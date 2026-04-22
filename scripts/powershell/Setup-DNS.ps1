# Setup-DNS.ps1
# Run on DC01 after AD DS is installed and domain corp.gmbh is created
# DC01 private IP: 10.0.0.4

# Add reverse lookup zone
Add-DnsServerPrimaryZone -NetworkId "10.0.0.0/24" `
    -ReplicationScope Domain -DynamicUpdate Secure

# Add static A records
Add-DnsServerResourceRecordA -Name "srv01" -ZoneName "corp.gmbh" `
    -IPv4Address "10.0.0.20" -CreatePtr

Add-DnsServerResourceRecordA -Name "linux01" -ZoneName "corp.gmbh" `
    -IPv4Address "10.0.0.6" -CreatePtr

# Add CNAME aliases for services
Add-DnsServerResourceRecordCName -Name "helpdesk" -ZoneName "corp.gmbh" `
    -HostNameAlias "srv01.corp.gmbh"

Add-DnsServerResourceRecordCName -Name "monitoring" -ZoneName "corp.gmbh" `
    -HostNameAlias "srv01.corp.gmbh"

# Set external forwarders
Set-DnsServerForwarder -IPAddress "8.8.8.8","1.1.1.1"

Write-Host "DNS configured successfully." -ForegroundColor Green
Get-DnsServerResourceRecord -ZoneName "corp.gmbh" | Format-Table -AutoSize