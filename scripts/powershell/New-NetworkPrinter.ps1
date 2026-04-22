# New-NetworkPrinter.ps1
# Installs a network printer on a workstation
# Run as L1 support on the affected machine
#
# Usage:
#   .\New-NetworkPrinter.ps1 -PrinterIP "10.0.0.100" -PrinterName "Drucker-Etage1-Farbe"

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PrinterIP,
    [Parameter(Mandatory)] [string]$PrinterName,
    [string]$DriverName = "Generic / Text Only"
)

Write-Host "=== Installing Network Printer ===" -ForegroundColor Cyan
Write-Host "Printer: $PrinterName"
Write-Host "IP:      $PrinterIP"

# Step 1: Test connectivity
Write-Host ""
Write-Host "[1/4] Testing connectivity to printer..."
$Ping = Test-NetConnection -ComputerName $PrinterIP -Port 9100 -WarningAction SilentlyContinue
if (-not $Ping.TcpTestSucceeded) {
    Write-Error "Cannot reach printer at $PrinterIP on port 9100. Check network and printer power."
    exit 1
}
Write-Host "Printer reachable." -ForegroundColor Green

# Step 2: Add printer port
Write-Host "[2/4] Adding printer port..."
$PortName = "IP_$PrinterIP"
if (-not (Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue)) {
    Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP
    Write-Host "Port $PortName created." -ForegroundColor Green
} else {
    Write-Host "Port already exists." -ForegroundColor Yellow
}

# Step 3: Add printer
Write-Host "[3/4] Adding printer..."
if (-not (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue)) {
    Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName
    Write-Host "Printer $PrinterName added." -ForegroundColor Green
} else {
    Write-Host "Printer already installed." -ForegroundColor Yellow
}

# Step 4: Print test page
Write-Host "[4/4] Done. To print a test page run:"
Write-Host "  (New-Object -ComObject WScript.Network).SetDefaultPrinter('$PrinterName')"
Write-Host ""
Write-Host "Printer installation complete." -ForegroundColor Green