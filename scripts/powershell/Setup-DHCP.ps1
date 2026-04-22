# Setup-DHCP.ps1
# Run on DC01 after AD DS is installed
# DC01 private IP: 10.0.0.4
# Subnet: 10.0.0.0/24

# Install DHCP role
Install-WindowsFeature DHCP -IncludeManagementTools

# Authorize DHCP server in AD
Add-DhcpServerInDC -DnsName "DC01.corp.gmbh" -IPAddress 10.0.0.4

# Create scope
Add-DhcpServerv4Scope -Name "CorpNet-LAN" `
    -StartRange 10.0.0.100 `
    -EndRange 10.0.0.200 `
    -SubnetMask 255.255.255.0 `
    -LeaseDuration 8:00:00 `
    -State Active

# Set scope options (no router needed, Azure handles routing)
Set-DhcpServerv4OptionValue `
    -ScopeId 10.0.0.0 `
    -DnsServer 10.0.0.4 `
    -DnsDomain "corp.gmbh"

# Exclude static IP range (.1 to .50 reserved for servers)
Add-DhcpServerv4ExclusionRange `
    -ScopeId 10.0.0.0 `
    -StartRange 10.0.0.1 `
    -EndRange 10.0.0.50

# Add reservation for LINUX01
Add-DhcpServerv4Reservation `
    -ScopeId 10.0.0.0 `
    -IPAddress 10.0.0.6 `
    -ClientId "00-00-00-00-00-06" `
    -Name "LINUX01" `
    -Description "Ubuntu Server"

Write-Host "DHCP configured successfully." -ForegroundColor Green
Get-DhcpServerv4Scope | Format-Table -AutoSize