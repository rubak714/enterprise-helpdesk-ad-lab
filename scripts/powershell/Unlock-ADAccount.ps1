# Unlock-ADAccount.ps1
# L1 Helpdesk script to unlock an AD account and investigate the lockout source
#
# Usage:
#   .\Unlock-ADAccount.ps1 -Username "stefan.hoffmann" -TicketNumber "INC-2026-0002"

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Username,
    [Parameter(Mandatory)] [string]$TicketNumber
)

#Requires -Modules ActiveDirectory
$ErrorActionPreference = "Stop"

# Get user details
try {
    $User = Get-ADUser -Identity $Username -Properties `
        LockedOut, LastBadPasswordAttempt, BadLogonCount, Department, Title
} catch {
    Write-Error "User '$Username' not found."
    exit 1
}

Write-Host "=== Account Status ===" -ForegroundColor Cyan
Write-Host "User:        $($User.Name)"
Write-Host "Department:  $($User.Department)"
Write-Host "Locked Out:  $($User.LockedOut)"
Write-Host "Bad Logons:  $($User.BadLogonCount)"
Write-Host "Last Bad:    $($User.LastBadPasswordAttempt)"

if (-not $User.LockedOut) {
    Write-Host "Account is NOT locked. No action needed." -ForegroundColor Yellow
    exit 0
}

# Find lockout source from PDC
Write-Host ""
Write-Host "=== Investigating Lockout Source ===" -ForegroundColor Cyan
$PDC = (Get-ADDomainController -Discover -Service PrimaryDC).HostName
Write-Host "Querying PDC: $PDC"

try {
    $LockoutEvents = Get-WinEvent -ComputerName $PDC -FilterHashtable @{
        LogName   = "Security"
        Id        = 4740
        StartTime = (Get-Date).AddHours(-24)
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.Properties[0].Value -eq $Username
    } | Select-Object -First 5

    if ($LockoutEvents) {
        Write-Host "Lockout events found:" -ForegroundColor Yellow
        foreach ($Event in $LockoutEvents) {
            $CallerComputer = $Event.Properties[1].Value
            Write-Host "  Time: $($Event.TimeCreated)  Source: $CallerComputer"
        }
    } else {
        Write-Host "No lockout events found in last 24 hours."
        Write-Host "Check for cached credentials on mobile devices or mapped drives."
    }
} catch {
    Write-Warning "Could not query PDC events: $_"
}

# Unlock the account
try {
    Unlock-ADAccount -Identity $Username
    Write-Host ""
    Write-Host "Account UNLOCKED successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to unlock account: $_"
    exit 1
}

# Write audit log
$AuditLog = "C:\Setup\Logs\AccountUnlocks\$(Get-Date -Format 'yyyy-MM').csv"
$LogDir = Split-Path $AuditLog
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }

[PSCustomObject]@{
    Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Technician    = $env:USERNAME
    Username      = $Username
    TicketNumber  = $TicketNumber
    BadLogonCount = $User.BadLogonCount
    LockoutSource = if ($LockoutEvents) { $LockoutEvents[0].Properties[1].Value } else { "Unknown" }
} | Export-Csv -Path $AuditLog -Append -NoTypeInformation

Write-Host "Audit logged to: $AuditLog"