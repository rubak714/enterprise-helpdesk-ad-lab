# Reset-UserPassword.ps1
# L1 Helpdesk script to reset a user password with audit logging
#
# Usage:
#   .\Reset-UserPassword.ps1 -Username "anna.becker" -TicketNumber "INC-2026-0001"
#
# Run as: member of GRP-IT-L1-Support on DC01

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $false)]
    [string]$TemporaryPassword,

    [Parameter(Mandatory = $true)]
    [string]$TicketNumber
)

#Requires -Modules ActiveDirectory
$ErrorActionPreference = "Stop"
$AuditLog = "C:\Setup\Logs\PasswordResets\$(Get-Date -Format 'yyyy-MM').csv"
$Technician = $env:USERNAME

function New-RandomPassword {
    $Upper   = [char[]](65..90)  | Get-Random -Count 3
    $Lower   = [char[]](97..122) | Get-Random -Count 5
    $Digits  = [char[]](48..57)  | Get-Random -Count 4
    $Special = [char[]]('!@#%&?') | Get-Random -Count 2
    $All = ($Upper + $Lower + $Digits + $Special) | Sort-Object { Get-Random }
    return -join $All
}

# Step 1: Verify user exists
try {
    $User = Get-ADUser -Identity $Username -Properties `
        LockedOut, Enabled, PasswordLastSet, Department, Title
} catch {
    Write-Error "User '$Username' not found in Active Directory."
    exit 1
}

if (-not $User.Enabled) {
    Write-Warning "Account '$Username' is DISABLED. Contact L2 to re-enable first."
    exit 1
}

# Step 2: Identity verification reminder
Write-Host ""
Write-Host "=== IDENTITY VERIFICATION ===" -ForegroundColor Yellow
Write-Host "Verify the caller's identity before resetting:"
Write-Host "  Name:       $($User.Name)"
Write-Host "  Department: $($User.Department)"
Write-Host "  Title:      $($User.Title)"
Write-Host ""
$Confirm = Read-Host "Have you verified the caller's identity? (yes/no)"
if ($Confirm -ne "yes") {
    Write-Host "Password reset cancelled. Always verify identity first." -ForegroundColor Red
    exit 0
}

# Step 3: Generate or use provided password
if ([string]::IsNullOrEmpty($TemporaryPassword)) {
    $TempPwd = New-RandomPassword
    Write-Host "Generated temporary password: $TempPwd" -ForegroundColor Green
} else {
    $TempPwd = $TemporaryPassword
}

# Step 4: Reset the password
try {
    $SecurePwd = ConvertTo-SecureString $TempPwd -AsPlainText -Force
    Set-ADAccountPassword -Identity $Username -NewPassword $SecurePwd -Reset
    Set-ADUser -Identity $Username -ChangePasswordAtLogon $true

    if ($User.LockedOut) {
        Unlock-ADAccount -Identity $Username
        Write-Host "Account was locked, unlocked automatically." -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "Password reset successful for $Username" -ForegroundColor Green
    Write-Host "User must change password at next logon."
} catch {
    Write-Error "Failed to reset password: $_"
    exit 1
}

# Step 5: Write audit log
$LogDir = Split-Path $AuditLog
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }

[PSCustomObject]@{
    Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Technician   = $Technician
    Username     = $Username
    Action       = "PasswordReset"
    TicketNumber = $TicketNumber
    WasLocked    = $User.LockedOut
    Result       = "Success"
} | Export-Csv -Path $AuditLog -Append -NoTypeInformation

Write-Host "Audit logged to: $AuditLog"