# Get-SystemInfo.ps1
# L1 Helpdesk script to collect basic system information for troubleshooting
#
# Usage:
#   .\Get-SystemInfo.ps1
#   .\Get-SystemInfo.ps1 -ComputerName "CLIENT01"

[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME
)

Write-Host "=== System Info: $ComputerName ===" -ForegroundColor Cyan

$OS = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName
$CS = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $ComputerName
$Disk = Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $ComputerName -Filter "DriveType=3"

Write-Host ""
Write-Host "OS:           $($OS.Caption)"
Write-Host "Last Boot:    $($OS.LastBootUpTime)"
Write-Host "Uptime:       $([math]::Round((New-TimeSpan -Start $OS.LastBootUpTime).TotalHours, 1)) hours"
Write-Host "RAM Total:    $([math]::Round($CS.TotalPhysicalMemory / 1GB, 1)) GB"
Write-Host "RAM Free:     $([math]::Round($OS.FreePhysicalMemory / 1MB, 1)) GB"
Write-Host "Domain:       $($CS.Domain)"

Write-Host ""
Write-Host "=== Disk Usage ===" -ForegroundColor Cyan
foreach ($D in $Disk) {
    $UsedPct = [math]::Round((($D.Size - $D.FreeSpace) / $D.Size) * 100, 1)
    $FreeGB = [math]::Round($D.FreeSpace / 1GB, 1)
    $TotalGB = [math]::Round($D.Size / 1GB, 1)
    $Color = if ($UsedPct -gt 90) { "Red" } elseif ($UsedPct -gt 75) { "Yellow" } else { "Green" }
    Write-Host "  $($D.DeviceID) $UsedPct% used ($FreeGB GB free of $TotalGB GB)" -ForegroundColor $Color
}

Write-Host ""
Write-Host "=== Network ===" -ForegroundColor Cyan
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" } | ForEach-Object {
    Write-Host "  $($_.InterfaceAlias): $($_.IPAddress)"
}

Write-Host ""
Write-Host "=== Top 5 CPU Processes ===" -ForegroundColor Cyan
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU, WorkingSet | Format-Table -AutoSize