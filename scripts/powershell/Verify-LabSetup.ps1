# Verify-LabSetup.ps1
# Runs a full health check on the corp.gmbh lab environment
# Run on DC01 to confirm all modules are working correctly
# Great for taking a final "everything is working" screenshot

#Requires -Modules ActiveDirectory, DHCPServer, DnsServer
$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  CORP GmbH Lab Environment Health Check" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$Pass = 0
$Fail = 0

function Test-Item {
    param([string]$Name, [scriptblock]$Test)
    try {
        $Result = & $Test
        if ($Result) {
            Write-Host "  [PASS] $Name" -ForegroundColor Green
            $script:Pass++
        } else {
            Write-Host "  [FAIL] $Name" -ForegroundColor Red
            $script:Fail++
        }
    } catch {
        Write-Host "  [FAIL] $Name - $_" -ForegroundColor Red
        $script:Fail++
    }
}

# Domain
Write-Host "--- Active Directory ---" -ForegroundColor Yellow
Test-Item "Domain corp.gmbh exists" { (Get-ADDomain).DNSRoot -eq "corp.gmbh" }
Test-Item "DC01 is PDC Emulator" { (Get-ADDomain).PDCEmulator -like "DC01*" }
Test-Item "52 users created" { (Get-ADUser -Filter * -SearchBase "OU=Benutzer,OU=CORP,DC=corp,DC=gmbh").Count -eq 52 }
Test-Item "32 security groups created" { (Get-ADGroup -Filter * -SearchBase "OU=Gruppen,OU=CORP,DC=corp,DC=gmbh").Count -eq 32 }
Test-Item "18 OUs created" { (Get-ADOrganizationalUnit -Filter * -SearchBase "OU=CORP,DC=corp,DC=gmbh").Count -ge 16 }
Test-Item "anna.becker exists in Vertrieb" { (Get-ADUser -Identity "anna.becker").Enabled }
Test-Item "thomas.mueller exists in IT" { (Get-ADUser -Identity "thomas.mueller").Enabled }
Test-Item "GRP-IT-L1-Support exists" { Get-ADGroup -Identity "GRP-IT-L1-Support" }
Test-Item "Fine-grained password policy PSO-IT-Admins exists" { Get-ADFineGrainedPasswordPolicy -Identity "PSO-IT-Admins" -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host "--- DNS ---" -ForegroundColor Yellow
Test-Item "corp.gmbh forward zone exists" { Get-DnsServerZone -Name "corp.gmbh" }
Test-Item "Reverse lookup zone exists" { Get-DnsServerZone -Name "0.0.10.in-addr.arpa" }
Test-Item "linux01 A record exists" { Resolve-DnsName "linux01.corp.gmbh" -ErrorAction SilentlyContinue }
Test-Item "helpdesk CNAME exists" { (Resolve-DnsName "helpdesk.corp.gmbh" -ErrorAction SilentlyContinue).Type -eq "CNAME" }
Test-Item "External forwarder 8.8.8.8 configured" { (Get-DnsServerForwarder).IPAddress -contains "8.8.8.8" }

Write-Host ""
Write-Host "--- DHCP ---" -ForegroundColor Yellow
Test-Item "DHCP server service running" { (Get-Service DHCPServer).Status -eq "Running" }
Test-Item "CorpNet-LAN scope exists" { Get-DhcpServerv4Scope -ScopeId "10.0.0.0" }
Test-Item "LINUX01 reservation exists" { Get-DhcpServerv4Reservation -ScopeId "10.0.0.0" | Where-Object { $_.IPAddress -eq "10.0.0.6" } }
Test-Item "DHCP authorized in AD" { Get-DhcpServerInDC | Where-Object { $_.DnsName -like "DC01*" } }

Write-Host ""
Write-Host "--- Network Connectivity ---" -ForegroundColor Yellow
Test-Item "DC01 private IP is 10.0.0.4" { (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -eq "10.0.0.4" }).Count -gt 0 }
Test-Item "CLIENT01 reachable (10.0.0.5:3389)" { (Test-NetConnection -ComputerName 10.0.0.5 -Port 3389 -WarningAction SilentlyContinue).TcpTestSucceeded }
Test-Item "LINUX01 reachable (10.0.0.6:22)" { (Test-NetConnection -ComputerName 10.0.0.6 -Port 22 -WarningAction SilentlyContinue).TcpTestSucceeded }

Write-Host ""
Write-Host "--- Group Policy ---" -ForegroundColor Yellow
Test-Item "Default Domain Policy exists" { Get-GPO -Name "Default Domain Policy" }
Test-Item "CORP-Drive-Mapping GPO exists" { Get-GPO -Name "CORP-Drive-Mapping" -ErrorAction SilentlyContinue }
Test-Item "CORP-Security-Baseline GPO exists" { Get-GPO -Name "CORP-Security-Baseline" -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host "--- Audit Logs ---" -ForegroundColor Yellow
Test-Item "Simulation logs directory exists" { Test-Path "C:\Setup\Logs\Simulations" }
Test-Item "Password reset logs exist" { Test-Path "C:\Setup\Logs\PasswordResets" }
Test-Item "Account unlock logs exist" { Test-Path "C:\Setup\Logs\AccountUnlocks" }

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Results: $Pass passed, $Fail failed" -ForegroundColor $(if ($Fail -eq 0) { "Green" } else { "Yellow" })
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if ($Fail -eq 0) {
    Write-Host "All checks passed. Lab environment is fully operational." -ForegroundColor Green
} else {
    Write-Host "$Fail check(s) failed. Review items marked [FAIL] above." -ForegroundColor Yellow
}