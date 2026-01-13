# Password Expiry Notifier – PowerShell

An enterprise-ready PowerShell automation that monitors Active Directory user password expiry and account status using the native `net user` command, sends staged email reminders, and maintains detailed audit logs.  
This solution does **not require the ActiveDirectory module**, making it suitable for restricted or locked-down environments.

---

## Features

- Reads user accounts from a CSV file
- Uses `net user` to fetch domain account details
- Identifies password expiry date, remaining days, expired passwords, and disabled accounts
- Sends automated email notifications:
  - 2 days before password expiry
  - 1 day before password expiry
  - On the day of expiry
  - After password expiration
  - When an account is disabled
- Maintains timestamped audit logs for auditing and troubleshooting
- Designed for unattended execution using Windows Task Scheduler

---

## Project Structure

Password-Expiry-Notifier-PowerShell
│
├── Users
│ └── users.csv
│
├── Logs
│ └── PasswordExpiry.log
│
├── Scripts
│ └── PasswordExpiryNotifier.ps1
│
└── README.md


---

## CSV File Format

```csv
Username,Email
john.doe,john.doe@company.com
jane.smith,jane.smith@company.com


## Configuration

### Update the following variables in the script before execution:

$CsvPath    = "D:\Projects\PasswordExpiryNotifier\Users\users.csv"
$LogPath    = "D:\Projects\PasswordExpiryNotifier\Logs\PasswordExpiry.log"
$SmtpServer = "smtp.company.com"
$From       = "it-support@company.com"



## How It Works

1. Imports user details from a CSV file

2. Executes net user <username> to retrieve domain account information

3. Parses account active status and password expiry date

4. Calculates remaining days until password expiry

5. Sends appropriate email notifications based on expiry timeline

6. Logs all actions, decisions, and errors with timestamps


## Sample Log Output
2026-01-13 22:10:01 - Processing user: john.doe
2026-01-13 22:10:01 - Password expiry: 2026-01-15 | Days left: 2 | Account Active: Yes
2026-01-13 22:10:01 - 2-day reminder sent to john.doe

## Requirements

* Windows domain-joined system
* PowerShell 5.1 or later
* SMTP relay access
* Permission to execute net user command

## Scheduling Recommendation

* Run the script daily using Windows Task Scheduler:
* Run with highest privileges
* Use a service account
* Schedule during off-business hours

## Limitations

* Relies on parsing net user command output
* SMTP credentials must be secured in production
* Accounts with passwords set to "Never Expires" are logged and skipped

## Future Enhancements
* HTML email templates
* Manager escalation for expired accounts
* Centralized IT summary report
* Secure credential vault integration

#Author

Naveen Sathi
PowerShell Automation Engineer