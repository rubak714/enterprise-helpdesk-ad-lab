# Join-Domain.ps1
# Joins a Windows machine to corp.gmbh domain
# Run on CLIENT01 as local administrator
#
# Usage:
#   .\Join-Domain.ps1

$DomainName = "corp.gmbh"
$DomainController = "10.0.0.4"

Write-Host "=== Joining $env:COMPUTERNAME to $DomainName ===" -ForegroundColor Cyan

# Step 1: Set DNS to point to DC01
Write-Host "[1/3] Setting DNS to DC01 ($DomainController)..."
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $DomainController

# Step 2: Test DNS resolution
Write-Host "[2/3] Testing DNS resolution..."
$Result = Resolve-DnsName $DomainName -ErrorAction SilentlyContinue
if ($Result) {
    Write-Host "DNS OK. $DomainName resolves to $($Result.IPAddress)" -ForegroundColor Green
} else {
    Write-Error "DNS resolution failed. Check that DC01 is running and reachable."
    exit 1
}

# Step 3: Join the domain
Write-Host "[3/3] Joining domain. Enter domain admin credentials when prompted..."
Add-Computer -DomainName $DomainName -Restart -Force

Write-Host "Domain join initiated. Computer will restart." -ForegroundColor Green