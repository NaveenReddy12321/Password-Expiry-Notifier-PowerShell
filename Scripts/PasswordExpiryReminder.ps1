# ==============================
# CONFIGURATION
# ==============================
$CsvPath   = "C:\passwordexpiryremainder\Users\users.csv"
$LogPath   = "C:\passwordexpiryremainder\Logs\PasswordExpiry.log"

$SmtpServer = "smtp.company.com"
$From       = "it-support@company.com"

# ==============================
# LOG FUNCTION
# ==============================
function Write-Log {
    param ($Message)
    Add-Content -Path $LogFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}
if(-not(Test-Path $LogPath)){
    New-Item -ItemType file -Path $LogPath
}

# ==============================
# MAIL FUNCTION
# ==============================
function Send-ReminderMail {
    param ($To, $Subject, $Body)

    Send-MailMessage `
        -From $From `
        -To $To `
        -Subject $Subject `
        -Body $Body `
        -SmtpServer $SmtpServer

    Write-Log "Mail sent to $To | Subject: $Subject"
}

# ==============================
# START SCRIPT
# ==============================
Write-Log "==== Script Started ===="

$Users = Import-Csv $CsvPath

foreach ($User in $Users) {

    Write-Log "Processing user: $($User.Username)"

    $Output = net user $($User.Username) 2>&1

    if ($Output -match "The user name could not be found") {
        Write-Log "User not found: $($User.Username)"
        continue
    }

    # ------------------------------
    # Extract Account Active Status
    # ------------------------------
    $AccountActive = ($Output | Select-String "Account active").ToString().Split(":")[1].Trim()

    # ------------------------------
    # Extract Password Expiry Date
    # ------------------------------
    $ExpiryLine = ($Output | Select-String "Password expires").ToString()

    if ($ExpiryLine -match "Never") {
        Write-Log "Password never expires for $($User.Username)"
        continue
    }

    $ExpiryDate = [datetime]($ExpiryLine.Split(":")[1].Trim())
    $DaysLeft   = ($ExpiryDate.Date - (Get-Date).Date).Days

    # ------------------------------
    # ACCOUNT DISABLED CHECK
    # ------------------------------
    if ($AccountActive -eq "No") {
        Send-ReminderMail `
            -To $User.Email `
            -Subject "Account Disabled Notification" `
            -Body "Your domain account is currently DISABLED. Please contact IT Support."

        Write-Log "Account disabled for $($User.Username)"
        continue
    }

    # ------------------------------
    # PASSWORD EXPIRY CHECKS
    # ------------------------------
    switch ($DaysLeft) {

        2 {
            Send-ReminderMail `
                -To $User.Email `
                -Subject "Password Expiry Reminder (2 Days Left)" `
                -Body "Your domain password will expire in 2 days. Please reset it."

            Write-Log "2-day reminder sent to $($User.Username)"
        }

        1 {
            Send-ReminderMail `
                -To $User.Email `
                -Subject "Password Expiry Reminder (1 Day Left)" `
                -Body "Your domain password will expire tomorrow. Please reset it immediately."

            Write-Log "1-day reminder sent to $($User.Username)"
        }

        0 {
            Send-ReminderMail `
                -To $User.Email `
                -Subject "Password Expiring Today" `
                -Body "Your domain password expires today. Please reset it now."

            Write-Log "Same-day reminder sent to $($User.Username)"
        }

        { $_ -lt 0 } {
            Send-ReminderMail `
                -To $User.Email `
                -Subject "Password Expired" `
                -Body "Your domain password has already expired. Please contact IT Support."

            Write-Log "Expired password mail sent to $($User.Username)"
        }

        default {
            Write-Log "No action required for $($User.Username). Days left: $DaysLeft"
        }
    }
}

Write-Log "==== Script Completed ===="
