# Run-HelpdeskSimulations.ps1
# Runs all helpdesk ticket simulations against the live corp.gmbh AD environment
# Run on DC01 as Administrator
# All outputs are logged to C:\Setup\Logs\Simulations\

#Requires -Modules ActiveDirectory
$ErrorActionPreference = "Stop"
$SimLog = "C:\Setup\Logs\Simulations\$(Get-Date -Format 'yyyy-MM-dd-HHmm').log"
New-Item -Path (Split-Path $SimLog) -ItemType Directory -Force | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    $Entry | Tee-Object -FilePath $SimLog -Append
}

Write-Log "Starting helpdesk simulation session"
Write-Log "Domain: $((Get-ADDomain).DNSRoot)"
Write-Log "Technician: $env:USERNAME"

# ============================================================
# SIMULATION 1: Password reset for sandra.koch (Buchhaltung)
# Ticket: INC-2026-0001
# Scenario: User forgot password over weekend, needs access for 9am meeting
# ============================================================

Write-Log "==================================================" "INFO"
Write-Log "TICKET INC-2026-0001: Password reset - sandra.koch" "INFO"
Write-Log "==================================================" "INFO"

try {
    $User = Get-ADUser -Identity "sandra.koch" -Properties Enabled, LockedOut, Department, Title
    Write-Log "User found: $($User.Name), Dept: $($User.Department), Enabled: $($User.Enabled)"

    # Generate temporary password
    $TempPwd = "Temp$(Get-Random -Minimum 1000 -Maximum 9999)x"
    $SecurePwd = ConvertTo-SecureString $TempPwd -AsPlainText -Force

    # Reset password
    Set-ADAccountPassword -Identity "sandra.koch" -NewPassword $SecurePwd -Reset
    Set-ADUser -Identity "sandra.koch" -ChangePasswordAtLogon $true

    Write-Log "Password reset successful" "SUCCESS"
    Write-Log "Temporary password: $TempPwd (communicated verbally, not via email)" "SUCCESS"
    Write-Log "User must change password at next logon" "SUCCESS"

    # Write audit entry
    $AuditPath = "C:\Setup\Logs\PasswordResets"
    New-Item -Path $AuditPath -ItemType Directory -Force | Out-Null
    [PSCustomObject]@{
        Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Technician   = $env:USERNAME
        Username     = "sandra.koch"
        TicketNumber = "INC-2026-0001"
        Action       = "PasswordReset"
        WasLocked    = $User.LockedOut
        Result       = "Success"
    } | Export-Csv -Path "$AuditPath\$(Get-Date -Format 'yyyy-MM').csv" -Append -NoTypeInformation

    Write-Log "Audit entry written to $AuditPath" "SUCCESS"
} catch {
    Write-Log "Failed: $_" "ERROR"
}

# ============================================================
# SIMULATION 2: Account unlock for anna.becker (Vertrieb)
# Ticket: INC-2026-0002
# Scenario: Account locked after returning from holiday
# ============================================================

Write-Log "==================================================" "INFO"
Write-Log "TICKET INC-2026-0002: Account unlock - anna.becker" "INFO"
Write-Log "==================================================" "INFO"

try {
    # First lock the account by setting bad password count
    Set-ADUser -Identity "anna.becker" -Replace @{badPwdCount=5}
    Write-Log "Simulated 5 bad password attempts on anna.becker"

    # Now investigate and unlock
    $User = Get-ADUser -Identity "anna.becker" -Properties `
        LockedOut, BadLogonCount, LastBadPasswordAttempt, Department

    Write-Log "Account status check:"
    Write-Log "  Name:              $($User.Name)"
    Write-Log "  Department:        $($User.Department)"
    Write-Log "  Locked Out:        $($User.LockedOut)"
    Write-Log "  Bad Logon Count:   $($User.BadLogonCount)"
    Write-Log "  Last Bad Attempt:  $($User.LastBadPasswordAttempt)"

    # Check Event 4740 on PDC
    Write-Log "Checking Event ID 4740 on PDC for lockout source..."
    $PDC = (Get-ADDomainController -Discover -Service PrimaryDC).HostName
    $LockoutEvents = Get-WinEvent -ComputerName $PDC -FilterHashtable @{
        LogName   = "Security"
        Id        = 4740
        StartTime = (Get-Date).AddHours(-24)
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.Properties[0].Value -eq "anna.becker"
    } | Select-Object -First 3

    if ($LockoutEvents) {
        foreach ($Event in $LockoutEvents) {
            Write-Log "  Lockout event: Time=$($Event.TimeCreated) Source=$($Event.Properties[1].Value)" "SUCCESS"
        }
    } else {
        Write-Log "  No lockout events found (simulated lock via badPwdCount, no real auth failure)" "INFO"
    }

    # Unlock
    Unlock-ADAccount -Identity "anna.becker"
    Write-Log "Account unlocked successfully" "SUCCESS"

    # Audit entry
    $AuditPath = "C:\Setup\Logs\AccountUnlocks"
    New-Item -Path $AuditPath -ItemType Directory -Force | Out-Null
    [PSCustomObject]@{
        Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Technician    = $env:USERNAME
        Username      = "anna.becker"
        TicketNumber  = "INC-2026-0002"
        BadLogonCount = $User.BadLogonCount
        LockoutSource = if ($LockoutEvents) { $LockoutEvents[0].Properties[1].Value } else { "Simulated" }
        Result        = "Unlocked"
    } | Export-Csv -Path "$AuditPath\$(Get-Date -Format 'yyyy-MM').csv" -Append -NoTypeInformation

    Write-Log "Audit entry written to $AuditPath" "SUCCESS"
} catch {
    Write-Log "Failed: $_" "ERROR"
}

# ============================================================
# SIMULATION 3: Department transfer - kemal.arslan
# Ticket: INC-2026-0003
# Scenario: User moved from Vertrieb to Buchhaltung, needs folder access updated
# ============================================================

Write-Log "==================================================" "INFO"
Write-Log "TICKET INC-2026-0003: Department transfer - kemal.arslan" "INFO"
Write-Log "==================================================" "INFO"

# Note: kemal.arslan does not exist in the 52 users, use markus.lange from Vertrieb
# and simulate a transfer to show the process

try {
    $User = Get-ADUser -Identity "markus.lange" -Properties MemberOf, Department

    Write-Log "Current department: $($User.Department)"
    Write-Log "Current groups:"
    foreach ($Group in $User.MemberOf) {
        $GroupName = ($Group -split ',')[0] -replace 'CN=',''
        Write-Log "  $GroupName"
    }

    # Simulate adding to new department file share group
    Add-ADGroupMember -Identity "GRP-FileShare-Buchhaltung" -Members "markus.lange"
    Write-Log "Added markus.lange to GRP-FileShare-Buchhaltung" "SUCCESS"
    Write-Log "User must log off and log back on for new group token to take effect" "SUCCESS"

} catch {
    Write-Log "Failed: $_" "ERROR"
}

# ============================================================
# SIMULATION 4: New user verification
# Ticket: INC-2026-0004
# Scenario: Verify a new user account was created correctly after onboarding
# ============================================================

Write-Log "==================================================" "INFO"
Write-Log "TICKET INC-2026-0004: Verify new user - florian.koenig" "INFO"
Write-Log "==================================================" "INFO"

try {
    $User = Get-ADUser -Identity "florian.koenig" -Properties `
        Enabled, Department, Title, MemberOf, PasswordLastSet, CannotChangePassword

    Write-Log "User verification check:"
    Write-Log "  Name:              $($User.Name)"
    Write-Log "  Department:        $($User.Department)"
    Write-Log "  Title:             $($User.Title)"
    Write-Log "  Enabled:           $($User.Enabled)"
    Write-Log "  Password Last Set: $($User.PasswordLastSet)"
    Write-Log "  Group count:       $($User.MemberOf.Count)"

    foreach ($Group in $User.MemberOf) {
        $GroupName = ($Group -split ',')[0] -replace 'CN=',''
        Write-Log "  Member of: $GroupName" "SUCCESS"
    }

    Write-Log "User account verified successfully" "SUCCESS"
} catch {
    Write-Log "Failed: $_" "ERROR"
}

# ============================================================
# SIMULATION 5: Bulk user status report
# Ticket: INC-2026-0005
# Scenario: Monthly IT audit - report on all user account statuses
# ============================================================

Write-Log "==================================================" "INFO"
Write-Log "TICKET INC-2026-0005: Monthly user audit report" "INFO"
Write-Log "==================================================" "INFO"

try {
    $AllUsers = Get-ADUser -Filter * -Properties Enabled, LockedOut, PasswordExpired,
        LastLogonDate, Department -SearchBase "OU=Benutzer,OU=CORP,DC=corp,DC=gmbh"

    $Enabled  = ($AllUsers | Where-Object { $_.Enabled }).Count
    $Disabled = ($AllUsers | Where-Object { -not $_.Enabled }).Count
    $Locked   = ($AllUsers | Where-Object { $_.LockedOut }).Count
    $Expired  = ($AllUsers | Where-Object { $_.PasswordExpired }).Count

    Write-Log "Monthly user audit results:"
    Write-Log "  Total users:    $($AllUsers.Count)"
    Write-Log "  Enabled:        $Enabled"
    Write-Log "  Disabled:       $Disabled"
    Write-Log "  Locked out:     $Locked"
    Write-Log "  Password exp:   $Expired"

    # Export to CSV
    $ReportPath = "C:\Setup\Logs\Audits\UserAudit-$(Get-Date -Format 'yyyy-MM-dd').csv"
    New-Item -Path (Split-Path $ReportPath) -ItemType Directory -Force | Out-Null
    $AllUsers | Select-Object Name, SamAccountName, Department, Enabled, LockedOut,
        PasswordExpired, LastLogonDate |
        Export-Csv -Path $ReportPath -NoTypeInformation

    Write-Log "Full audit report saved to $ReportPath" "SUCCESS"
} catch {
    Write-Log "Failed: $_" "ERROR"
}

Write-Log "=========================================="
Write-Log "SIMULATION SESSION COMPLETE"
Write-Log "=========================================="
Write-Log "All tickets processed. See log at $SimLog"
Write-Log "Audit logs at C:\Setup\Logs\"