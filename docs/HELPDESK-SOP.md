# Standard Operating Procedures - CORP GmbH IT Support

## L1 - First Level Support

### SOP-001: Password Reset

**When:** User reports forgotten password or password expired.

**Before you start:** Verify the caller's identity. Ask for their full name,
department, and employee number. If calling by phone, call them back on their
registered extension.

**Steps:**
1. Open PowerShell as L1 support user
2. Run: `.\Reset-UserPassword.ps1 -Username "firstname.lastname" -TicketNumber "INC-XXXX"`
3. Communicate the temporary password to the user securely (never by email)
4. Confirm the user can log in and change their password
5. Document in ticket: who called, how identity was verified, result

### SOP-002: Account Unlock

**When:** User reports "account locked" error at login screen.

**Steps:**
1. Run: `.\Unlock-ADAccount.ps1 -Username "firstname.lastname" -TicketNumber "INC-XXXX"`
2. Check the lockout source in the output - this tells you WHICH machine caused it
3. If lockout source is unknown or repeated: ask user if they have old passwords
   saved in any mobile devices or mapped drives. These are the most common cause.
4. Document the lockout source in the ticket

### SOP-003: New Employee Setup

**When:** HR sends new employee notification (usually via ticket or email).

**Steps:**
1. Verify you have: full name, department, start date, manager name, required software
2. Run: `.\New-Employee.ps1` from Project 2, or create manually:
   - Create AD account in correct OU
   - Add to department group and file share group
   - Set temporary password with "must change at next logon"
3. Prepare workstation: domain join, install standard software
4. Create welcome email with login credentials and IT contact info
5. Schedule 15-min intro call for first day

### SOP-004: Printer Issue

**When:** User reports printer not working, jobs stuck, or wrong output.

**Steps:**
1. Ask: which printer? What error? What were you trying to print?
2. Check if the printer is online: `ping [printer-IP]`
3. If offline: check physical printer (power, paper, toner, jam indicator)
4. If online but jobs stuck: clear queue
   ```cmd
   net stop spooler
   del /Q %systemroot%\system32\spool\printers\*
   net start spooler
   ```
5. If driver issue: remove and reinstall printer (see New-NetworkPrinter.ps1)
6. If recurring: escalate to L2 for driver or GPO investigation

### SOP-005: Shared Drive Not Accessible

**When:** User cannot access a network share (permission denied or not found).

**Steps:**
1. Check if user can ping the file server: `ping srv01.corp.gmbh`
2. If no ping: check DNS settings (`nslookup srv01.corp.gmbh`)
3. If ping OK: check group membership:
   ```powershell
   Get-ADGroupMember "GRP-FileShare-Vertrieb" | Select Name
   ```
4. If user not in group: add them (requires ticket from their manager)
5. User must log off and log on again for new group membership to take effect
6. If still failing: check NTFS permissions on the share folder

### SOP-006: VPN Connection Issue

**When:** Remote user cannot connect to VPN or VPN connects but no internal access.

**Steps:**
1. Verify user has WireGuard installed and config file loaded
2. Check if user is in GRP-VPN-Users group
3. If connected but no internal access: likely DNS issue
   - Check if split DNS is configured in WireGuard client
   - Internal DNS should point to 10.0.0.4 (DC01)
4. If cannot connect at all:
   - Is UDP 51820 open on their network? (hotel/corporate firewalls may block)
   - Try mobile hotspot as a test
5. Escalate to L2 if server-side issue suspected

### SOP-007: Slow Computer

**When:** User reports laptop/desktop running slowly.

**Steps:**
1. Remote into machine or use Get-SystemInfo.ps1
2. Check disk space: less than 10% free = critical
3. Check RAM usage: Task Manager > Performance
4. Check startup programs: `msconfig` or Task Manager > Startup
5. Check for Windows Updates running in background
6. If disk full: help user archive old files, clear temp files
7. If RAM issue and machine is old: recommend hardware upgrade to L2

## L2 - Second Level Support

### SOP-008: Group Policy Not Applying

**When:** A GPO setting is not taking effect on a workstation or user.

**Steps:**
1. On the affected machine, run: `gpresult /R /scope:computer` and `gpresult /R /scope:user`
2. Check if the GPO appears under "Applied Group Policy Objects"
3. If not listed, check:
   - Is the GPO linked to the correct OU?
   - Is the GPO enabled? (not disabled at the link level)
   - Does the GPO have a WMI filter that is excluding this machine?
   - Security filtering: is the user/computer in the filter group?
4. Force update: `gpupdate /force` - some settings need logoff/logon or restart
5. Use RSoP (Resultant Set of Policy) for detailed analysis:
   `gpresult /H gpresult.html` and open in browser

### SOP-009: DHCP Issues

**When:** Clients getting APIPA addresses (169.254.x.x) or DHCP scope running low.

**Steps:**
1. Check DHCP scope status: `Get-DhcpServerv4ScopeStatistics`
2. If scope nearly full (>90% used):
   - Check for stale leases: `Get-DhcpServerv4Lease -ScopeId 10.0.0.0 | Where-Object LeaseExpiryTime -lt (Get-Date)`
   - Reduce lease duration if too long
   - Expand scope range if needed
3. If DHCP service not responding:
   - Check service: `Get-Service DHCPServer`
   - Check authorization: `Get-DhcpServerInDC`

### SOP-010: DNS Resolution Failure

**When:** Internal or external name resolution not working.

**Steps:**
1. Test internal: `nslookup dc01.corp.gmbh 10.0.0.4`
2. Test external: `nslookup google.com 10.0.0.4`
3. If internal fails: check DNS zone records
4. If external fails: check forwarder configuration
5. Clear DNS cache: `Clear-DnsServerCache` (server) or `ipconfig /flushdns` (client)
6. Check zone health: `dcdiag /test:dns`

## L3 - Third Level Support

### SOP-011: AD Replication Failure

**Steps:**
1. Check replication status: `repadmin /replsummary`
2. Check specific errors: `repadmin /showrepl`
3. Force replication: `repadmin /syncall DC01 /AdeP`
4. If lingering objects: `repadmin /removelingeringobjects`
5. Check site links: `Get-ADReplicationSiteLink -Filter *`

### SOP-012: Full Disaster Recovery

**Prerequisites:** Recent System State backup, physical access to DC.

1. Boot into DSRM (Directory Services Restore Mode)
2. Restore System State: `wbadmin start systemstaterecovery -version:<version>`
3. If authoritative restore needed: `ntdsutil` > `authoritative restore`
4. Restart normally
5. Verify: `repadmin /replsummary`, `dcdiag /test:dns`, `dcdiag /test:sysvolcheck`
6. Document every step with timestamps