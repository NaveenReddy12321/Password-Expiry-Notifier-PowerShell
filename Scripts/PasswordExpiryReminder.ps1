# ================= INITIALIZATION =================
$BasePath = "D:\Projects\PasswordExpiryNotifier"

$Users   = Import-Csv "$BasePath\config\users.csv"
$Config  = Get-Content "$BasePath\config\settings.json" | ConvertFrom-Json
$Creds   = Import-Clixml "$BasePath\credentials\smtp_creds.xml"
$LogFile = "$BasePath\logs\PasswordExpiry.log"

$Today = (Get-Date).Date
$TargetDate = $Today.AddDays($Config.DaysBeforeExpiry)

function Write-Log {
    param ($Message)
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

# ================= PROCESS USERS =================
foreach ($User in $Users) {

    $Output = net user /domain $User.Username 2>$null
    if (-not $Output) {
        Write-Log "User not found: $($User.Username)"
        continue
    }

    $ExpiryLine = $Output | Where-Object { $_ -match "Password expires" }
    if ($ExpiryLine -match "Never") {
        Write-Log "Password never expires: $($User.Username)"
        continue
    }

    $ExpiryDate = [datetime]::Parse(
        ($ExpiryLine -replace "Password expires\s+", "").Trim()
    )

    # ---------- PASSWORD EXPIRED ----------
    if ($ExpiryDate.Date -lt $Today) {
        $Subject = "🚨 PASSWORD EXPIRED – IMMEDIATE ACTION REQUIRED"
        $Body = "Hello $($User.DisplayName),`n`nYour password expired on $ExpiryDate.`nContact IT Support immediately."

        Send-MailMessage -To $User.Email `
            -From $Config.SMTP.FromEmail `
            -Subject $Subject `
            -Body $Body `
            -SmtpServer $Config.SMTP.Server `
            -Port $Config.SMTP.Port `
            -UseSsl `
            -Credential $Creds

        Write-Log "Expired alert sent to $($User.Username)"
        continue
    }

    # ---------- EXPIRING IN 2 DAYS ----------
    if ($ExpiryDate.Date -eq $TargetDate) {
        $Subject = "⚠ Password Expiry Reminder (2 Days Left)"
        $Body = "Hello $($User.DisplayName),`n`nYour password will expire on $ExpiryDate.`nPlease change it."

        Send-MailMessage -To $User.Email `
            -From $Config.SMTP.FromEmail `
            -Subject $Subject `
            -Body $Body `
            -SmtpServer $Config.SMTP.Server `
            -Port $Config.SMTP.Port `
            -UseSsl `
            -Credential $Creds

        Write-Log "Reminder sent to $($User.Username)"
    }
}
