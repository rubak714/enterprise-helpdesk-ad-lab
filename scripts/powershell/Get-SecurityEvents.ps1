# Get-SecurityEvents.ps1
# Monitors and reports on security events in corp.gmbh
# Covers failed logins, account lockouts, and privilege use
# Run on DC01 as Domain Administrator
#
# Usage:
#   .\Get-SecurityEvents.ps1
#   .\Get-SecurityEvents.ps1 -Hours 48
#   .\Get-SecurityEvents.ps1 -ExportHTML

[CmdletBinding()]
param(
    [int]$Hours = 24,
    [switch]$ExportHTML
)

$StartTime = (Get-Date).AddHours(-$Hours)
$ReportPath = "C:\Setup\Logs\SecurityReports\SecurityReport-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
New-Item -Path (Split-Path "$ReportPath.html") -ItemType Directory -Force | Out-Null

Write-Host ""
Write-Host "=== CORP GmbH Security Event Report ===" -ForegroundColor Cyan
Write-Host "Period: Last $Hours hours (since $($StartTime.ToString('yyyy-MM-dd HH:mm')))"
Write-Host "Domain Controller: $env:COMPUTERNAME"
Write-Host ""

# ============================================================
# EVENT 4625: Failed login attempts
# ============================================================

Write-Host "=== Failed Login Attempts (Event 4625) ===" -ForegroundColor Yellow

try {
    $FailedLogins = Get-WinEvent -FilterHashtable @{
        LogName   = "Security"
        Id        = 4625
        StartTime = $StartTime
    } -ErrorAction SilentlyContinue

    if ($FailedLogins) {
        $FailedSummary = $FailedLogins | ForEach-Object {
            [PSCustomObject]@{
                Time        = $_.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                Username    = $_.Properties[5].Value
                Domain      = $_.Properties[6].Value
                Workstation = $_.Properties[13].Value
                IPAddress   = $_.Properties[19].Value
                FailureCode = $_.Properties[8].Value
            }
        }

        Write-Host "Total failed attempts: $($FailedLogins.Count)" -ForegroundColor Red
        $FailedSummary | Group-Object Username | Sort-Object Count -Descending | Select-Object -First 10 |
            ForEach-Object { Write-Host "  $($_.Count)x - $($_.Name)" }

        Write-Host ""
        Write-Host "Most recent 10 failed attempts:"
        $FailedSummary | Select-Object -First 10 | Format-Table Time, Username, Workstation, IPAddress -AutoSize
    } else {
        Write-Host "No failed login attempts in the last $Hours hours." -ForegroundColor Green
    }
} catch {
    Write-Host "Could not retrieve Event 4625: $_" -ForegroundColor Yellow
}

# ============================================================
# EVENT 4740: Account lockouts
# ============================================================

Write-Host "=== Account Lockouts (Event 4740) ===" -ForegroundColor Yellow

try {
    $Lockouts = Get-WinEvent -FilterHashtable @{
        LogName   = "Security"
        Id        = 4740
        StartTime = $StartTime
    } -ErrorAction SilentlyContinue

    if ($Lockouts) {
        Write-Host "Total lockout events: $($Lockouts.Count)" -ForegroundColor Red
        $Lockouts | ForEach-Object {
            [PSCustomObject]@{
                Time           = $_.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                LockedAccount  = $_.Properties[0].Value
                CallerComputer = $_.Properties[1].Value
            }
        } | Format-Table -AutoSize
    } else {
        Write-Host "No account lockouts in the last $Hours hours." -ForegroundColor Green
    }
} catch {
    Write-Host "Could not retrieve Event 4740: $_" -ForegroundColor Yellow
}

# ============================================================
# EVENT 4720: New user accounts created
# ============================================================

Write-Host "=== New User Accounts Created (Event 4720) ===" -ForegroundColor Yellow

try {
    $NewUsers = Get-WinEvent -FilterHashtable @{
        LogName   = "Security"
        Id        = 4720
        StartTime = $StartTime
    } -ErrorAction SilentlyContinue

    if ($NewUsers) {
        Write-Host "New accounts created: $($NewUsers.Count)"
        $NewUsers | ForEach-Object {
            [PSCustomObject]@{
                Time        = $_.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                NewAccount  = $_.Properties[0].Value
                CreatedBy   = $_.Properties[4].Value
            }
        } | Format-Table -AutoSize
    } else {
        Write-Host "No new accounts created in the last $Hours hours." -ForegroundColor Green
    }
} catch {
    Write-Host "Could not retrieve Event 4720: $_" -ForegroundColor Yellow
}

# ============================================================
# EVENT 4728/4732: Users added to privileged groups
# ============================================================

Write-Host "=== Users Added to Privileged Groups (Event 4728/4732) ===" -ForegroundColor Yellow

try {
    $GroupChanges = Get-WinEvent -FilterHashtable @{
        LogName   = "Security"
        Id        = @(4728, 4732, 4756)
        StartTime = $StartTime
    } -ErrorAction SilentlyContinue

    if ($GroupChanges) {
        Write-Host "Group membership changes: $($GroupChanges.Count)" -ForegroundColor Yellow
        $GroupChanges | ForEach-Object {
            [PSCustomObject]@{
                Time      = $_.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                Member    = $_.Properties[0].Value
                Group     = $_.Properties[2].Value
                ChangedBy = $_.Properties[6].Value
            }
        } | Format-Table -AutoSize
    } else {
        Write-Host "No privileged group changes in the last $Hours hours." -ForegroundColor Green
    }
} catch {
    Write-Host "Could not retrieve group change events" -ForegroundColor Yellow
}

# ============================================================
# CURRENT LOCKED ACCOUNTS
# ============================================================

Write-Host "=== Currently Locked Accounts ===" -ForegroundColor Yellow

$LockedAccounts = Search-ADAccount -LockedOut
if ($LockedAccounts) {
    Write-Host "Locked accounts found:" -ForegroundColor Red
    $LockedAccounts | Select-Object Name, SamAccountName, LastLogonDate | Format-Table -AutoSize
} else {
    Write-Host "No accounts currently locked." -ForegroundColor Green
}

# ============================================================
# RECENTLY DISABLED ACCOUNTS
# ============================================================

Write-Host "=== Accounts Disabled in Last $Hours Hours ===" -ForegroundColor Yellow

$RecentlyDisabled = Get-WinEvent -FilterHashtable @{
    LogName   = "Security"
    Id        = 4725
    StartTime = $StartTime
} -ErrorAction SilentlyContinue

if ($RecentlyDisabled) {
    $RecentlyDisabled | ForEach-Object {
        [PSCustomObject]@{
            Time        = $_.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
            Account     = $_.Properties[0].Value
            DisabledBy  = $_.Properties[4].Value
        }
    } | Format-Table -AutoSize
} else {
    Write-Host "No accounts disabled in the last $Hours hours." -ForegroundColor Green
}

# ============================================================
# EXPORT HTML REPORT
# ============================================================

if ($ExportHTML) {
    $HTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>CORP GmbH Security Report - $(Get-Date -Format 'yyyy-MM-dd')</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #666; border-bottom: 1px solid #ccc; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th { background: #444; color: white; padding: 8px; text-align: left; }
        td { padding: 6px 8px; border-bottom: 1px solid #ddd; }
        tr:nth-child(even) { background: #f5f5f5; }
        .ok { color: green; font-weight: bold; }
        .warn { color: orange; font-weight: bold; }
        .crit { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1>CORP GmbH Security Event Report</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    <p>Period: Last $Hours hours</p>
    <p>Domain Controller: $env:COMPUTERNAME</p>
    <h2>Summary</h2>
    <table>
        <tr><th>Event</th><th>Count</th><th>Status</th></tr>
        <tr><td>Failed logins (4625)</td><td>$(if($FailedLogins){$FailedLogins.Count}else{0})</td><td>$(if($FailedLogins -and $FailedLogins.Count -gt 10){"<span class='crit'>Review</span>"}else{"<span class='ok'>OK</span>"})</td></tr>
        <tr><td>Account lockouts (4740)</td><td>$(if($Lockouts){$Lockouts.Count}else{0})</td><td>$(if($Lockouts){"<span class='warn'>Review</span>"}else{"<span class='ok'>OK</span>"})</td></tr>
        <tr><td>New accounts (4720)</td><td>$(if($NewUsers){$NewUsers.Count}else{0})</td><td>$(if($NewUsers){"<span class='warn'>Verify</span>"}else{"<span class='ok'>OK</span>"})</td></tr>
        <tr><td>Currently locked</td><td>$(if($LockedAccounts){$LockedAccounts.Count}else{0})</td><td>$(if($LockedAccounts){"<span class='warn'>Action needed</span>"}else{"<span class='ok'>OK</span>"})</td></tr>
    </table>
</body>
</html>
"@
    $HTML | Out-File -FilePath "$ReportPath.html" -Encoding UTF8
    Write-Host ""
    Write-Host "HTML report saved to: $ReportPath.html" -ForegroundColor Green
    Write-Host "Open in browser: start '$ReportPath.html'"
}

Write-Host ""
Write-Host "=== Report Complete ===" -ForegroundColor Cyan
Write-Host "Run with -ExportHTML to save a formatted HTML report"
Write-Host "Run with -Hours 48 to check the last 48 hours"