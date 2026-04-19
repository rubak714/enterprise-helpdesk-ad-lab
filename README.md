# Enterprise Helpdesk and Active Directory Lab

A home lab environment simulating a small German company's IT infrastructure. I built this to get hands-on experience with Active Directory, Group Policy, and the kind of support tasks that come up every day in L1-L3 helpdesk work.

*Note on Infrastructure:* Originally designed for VirtualBox, this lab was migrated to **Microsoft Azure** to bypass local hardware RAM limitations (16GB) and ensure high performance for Windows 11 and Server 2025.

## ☁️ Why I built this
I have been helping family and friends with IT issues for years - password
resets, Wi-Fi troubleshooting, printer problems, setting up new laptops and system optimization for better speed and battery life etc. I also helped my German landlord set up their router, new mobile phone setup and fix mobile issues on multiple occasions. But none of that shows up on a CV.

So I decided to build the same kind of 'simulated' environment that a real company would have, document everything properly and show that I can help company and it's people with support work and administration related tasks systematically and not just 'I fixed my friend's laptop.'

## ☁️ What is in here

This lab simulates "CORP GmbH", which is a fictional German company with about 50 employees across five departments. The infrastructure includes:

- A Windows Server 2025 domain controller (named as - DC01) running AD DS, DNS and DHCP
- A Windows 11 workstation (named as - CLIENT01) joined to the domain
- An Ubuntu 22.04 server (named as - LINUX01) joined to AD via realmd/SSSD

## ☁️ Why is this lab Important?

Because I will be -

- Building multiple virtual machines
- Installing Windows and Linux
- Practising my Networking skills and permissions
- Creating an Active Directory environment
- Running snapshots and backups
- Experimenting freely
- Breaking things without breaking my real PC

Not to mention, I will also be able to test the lab by -

- Adding and managing users
- Resettings passwords
- Joining users or computers to a domain
- Troubleshooting network and DNS issues
- Simulating real help desk tickets

In short, I will have a mini DNS center in my PC!

## ☁️ How to set up this lab from scratch
*Update:* The infrastructure is now built inside an Azure Virtual Network (VNet) named CorpNet, consisting of:

### VMs

- DC01 (Windows Server 2025): The "Brain" of the company. Domain Controller, DNS, and DHCP.
- CLIENT01 (Windows 11): An employee workstation joined to the corp.gmbh domain.
- LINUX01 (Ubuntu 22.04): A Linux server integrated into the AD environment using realmd/SSSD.

## ☁️ Current Option: Cloud Deployment (Microsoft Azure)
To ensure the lab runs smoothly without slowing down my physical laptop, I used the following Azure resources:

- Virtual Network: 10.0.0.0/16 (Internal subnet for secure VM communication).

### VM Sizing:
- DC01: Standard_B2als_v2 - 2vcpus, 4GiB memory - Windows Server *2025* Datacenter: Azure Edition - x64 Gen2
- CLIENT01: Standard_DC1ds_v3 (1 vcpu, 8 GiB memory) - Windows 11 25H2 pro
- LINUX01: Standard_D2ads_v7 (2 vcpus, 8 GiB memory) - Ubuntu server 24.04 LTS

### Cost Management: 

Configured Auto-shutdown schedules to preserve Azure credits.

---

## ☁️ Module 1: Infrastructure Setup

### 🟦 Step 1: Virtual Network

Created `VNet-CorpNet` in resource group `RG-CorpGmbH`, Germany West Central. Address space `10.0.0.0/16` with one subnet `InternalSubnet` at `10.0.0.0/24`. All three VMs live on this subnet and communicate over private IPs only. Public internet access is restricted to RDP and SSH through Network Security Groups.

![VNet-CorpNet overview showing address space 10.0.0.0/16 and InternalSubnet](screenshots/module01-vnet-infra.png)

### 🟦 Step 2: DC01 - Domain Controller

Deployed DC01 as the first VM. This is the brain of the lab. Everything else depends on it.

| Setting | Value |
|---|---|
| Name | DC01 |
| OS | Windows Server 2025 Datacenter Azure Edition |
| Size | Standard_B2als_v2 (2 vCPU, 4 GiB RAM) |
| Private IP | 10.0.0.4 (static) |
| VNet | VNet-CorpNet / InternalSubnet |
| NSG | DC01-nsg |
| Location | Germany West Central |

![DC01 overview in Azure portal showing status Running and VNet-CorpNet/InternalSubnet](screenshots/module01-dc01-00.png)

![DC01 properties tab showing private IP 10.0.0.4, OS Windows Server 2025, agent status Ready](screenshots/module01-dc01-01.png)

![DC01 network settings showing NIC dc01172-f1c7547f, private IP 10.0.0.4, NSG DC01-nsg](screenshots/module01-dc01-02.png)

### 🟦 Step 3: CLIENT01 - Windows 11 Workstation

CLIENT01 simulates an employee's computer. It will join the corp.gmbh domain once DC01 is configured.

| Setting | Value |
|---|---|
| Name | CLIENT01 |
| OS | Windows 11 Pro 23H2 |
| Size | Standard_DC1ds_v3 (1 vCPU, 8 GiB RAM) |
| Private IP | 10.0.0.5 (static) |
| VNet | VNet-CorpNet / InternalSubnet |
| NSG | CLIENT01-nsg |
| Location | Germany West Central |

![CLIENT01 overview showing status Running, Germany West Central, VNet-CorpNet/InternalSubnet](screenshots/module01-client01-00.png)

![CLIENT01 properties tab showing private IP 10.0.0.5 and OS Windows](screenshots/module01-client01-01.png)

![CLIENT01 network settings showing NIC client01455-1c895c52, private IP 10.0.0.5, NSG CLIENT01-nsg](screenshots/module01-client01-02.png)

### 🟦 Step 4: LINUX01 - Ubuntu Server

LINUX01 is the Linux side of the lab. It will be integrated into Active Directory using realmd and SSSD.

| Setting | Value |
|---|---|
| Name | LINUX01 |
| OS | Ubuntu 24.04 LTS |
| Size | Standard_D2ads_v7 (2 vCPU, 8 GiB RAM) |
| Private IP | 10.0.0.6 (static) |
| VNet | VNet-CorpNet / InternalSubnet |
| NSG | LINUX01-nsg |
| Location | Germany West Central |

> *Note:* Standard_B1s was not available in Germany West Central. Used Standard_D2ads_v7 instead. See Issue #4 and Issue #11.

![LINUX01 overview showing status Running, OS Linux Ubuntu 24.04, Germany West Central](screenshots/module01-linux01-00.png)

![LINUX01 properties tab showing private IP 10.0.0.6, 2 vCPUs, 8 GiB RAM](screenshots/module01-linux01-01.png)

![LINUX01 network settings showing NIC linux01909-e0951cf3, private IP 10.0.0.6, NSG LINUX01-nsg](screenshots/module01-linux01-02.png)

### 🟦 Step 5: All three VMs running

![All three VMs running - CLIENT01, DC01, LINUX01 in RG-CorpGmbH, Germany West Central](screenshots/module01-compute-infra.png)

### 🟦 Step 6: RDP into DC01 and verify connectivity

RDP'd into DC01 using the downloaded RDP file. Server Manager opened confirming Windows Server 2025 is running.

![Server Manager dashboard on DC01 showing Welcome to Server Manager](screenshots/module01-server-dc01.png)

Then ran connectivity test from DC01 PowerShell to confirm all three VMs can reach each other over the internal subnet:

```powershell
Test-NetConnection -ComputerName 10.0.0.5 -Port 3389
Test-NetConnection -ComputerName 10.0.0.6 -Port 22
```

Azure blocks ICMP ping by default so TCP port test was used instead.

![PowerShell on DC01 showing TcpTestSucceeded True for both CLIENT01 port 3389 and LINUX01 port 22](screenshots/module01-test-connection-from-dc01.png)

Both returned `TcpTestSucceeded: True`. All three VMs are on the same subnet and talking to each other. Module 1 complete.

### 🟦 Step 7: Deallocate after session

After taking all screenshots, all three VMs were deallocated to stop compute charges. Public IPs were deleted. New public IPs will be assigned at the start of each session.

![All three VMs showing Stopped (deallocated) status in Azure portal](screenshots/module01-all-vms-stopped-running.png)

---

## ☁️ Module 2: Active Directory, DNS and DHCP

### 🟦 Step 1: Install AD DS role

Still in the same PowerShell session where connectivity was tested, installed the Active Directory Domain Services role:

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
```

The screenshot below shows the full context. At the top you can see the connectivity test results from the previous step (TcpTestSucceeded True for both VMs), then immediately below it the AD DS installation running and completing with `Success: True`, `Exit Code: Success`, and `Feature Result: Active Directory Domain Services, Group P...`.

![PowerShell showing connectivity test results followed immediately by AD DS installation completing with Success True](screenshots/module2-adds-install-00.png)

### 🟦 Step 2: Promote DC01 to domain controller

After AD DS installed, promoted DC01 to a domain controller and created the new forest `corp.gmbh`:

```powershell
Install-ADDSForest -DomainName "corp.gmbh" -InstallDns -Force
```

> Note: The first two attempts failed because copy-pasted parameters used Unicode em-dashes instead of ASCII hyphens, so PowerShell did not recognise them. Removed the extra parameters and Windows set the NetBIOS name CORP automatically. See Issue #5.

The screenshot below shows the promotion in progress. DC01 is running `Install-ADDSForest`, validating the environment, running all prerequisite tests successfully, then starting to install the new forest and configure the DNS Server service. The server restarted automatically after this completed.

![DC01 showing Install-ADDSForest running, all tests passed, installing new forest and configuring DNS service](screenshots/module2-install-addsforest-01.png)

### 🟦 Step 3: Confirm domain created

After the restart, RDP'd back into DC01 and ran:

```powershell
Get-ADDomain
Get-ADForest
```

`Get-ADDomain` confirmed: `DNSRoot: corp.gmbh`, `NetBIOSName: CORP`, `PDCEmulator: DC01.corp.gmbh`, `DomainMode: Windows2025Domain`. DC01 is running all five FSMO roles as the only domain controller.

![Get-ADDomain output showing DNSRoot corp.gmbh, NetBIOSName CORP, PDCEmulator DC01.corp.gmbh](screenshots/module2-domain-confirmed-03.png)

`Get-ADForest` confirmed: `ForestMode: Windows2025Forest`, `RootDomain: corp.gmbh`, `GlobalCatalogs: DC01.corp.gmbh`. The forest is running at Windows Server 2025 functional level.

![Get-ADForest output showing ForestMode Windows2025Forest, RootDomain corp.gmbh, GlobalCatalogs DC01.corp.gmbh](screenshots/module2-adforest-confirmed-02.png)

Then opened Active Directory Users and Computers to confirm the domain was visible which closes Issues #5:

```powershell
dsa.msc
```

![Active Directory Users and Computers showing corp.gmbh domain listed in the tree](screenshots/module2-aduc-empty-04.png)


### 🟦 Step 4: Configure DNS

Created `C:\CorpLab\Setup-DNS.ps1` on DC01 using Notepad and ran it:

```powershell
notepad C:\CorpLab\Setup-DNS.ps1
cd C:\CorpLab
.\Setup-DNS.ps1
```

The script added a reverse lookup zone for `10.0.0.0/24`, an A record for `linux01` at `10.0.0.6`, an A record for `srv01` at `10.0.0.20` reserved for a future file server, CNAME aliases for `helpdesk` and `monitoring` both pointing to `srv01.corp.gmbh`, and set external forwarders to `8.8.8.8` and `1.1.1.1`.

The output showed `DNS configured successfully` in green, followed by a full table of all records in the corp.gmbh zone including the A records, CNAME aliases, and all the Kerberos and LDAP SRV records that Active Directory created automatically.

![PowerShell showing DNS configured successfully with complete record table including dc01, linux01, helpdesk CNAME, monitoring CNAME, srv01](screenshots/module2-dns-zones-05.png)

Then opened DNS Manager to verify visually:

```powershell
dnsmgmt.msc
```

The DNS Manager showed the corp.gmbh forward lookup zone with all records: dc01 Host A at 10.0.0.4, linux01 Host A at 10.0.0.6, helpdesk Alias CNAME pointing to srv01.corp.gmbh, monitoring Alias CNAME pointing to srv01.corp.gmbh, and srv01 Host A at 10.0.0.20. Reverse Lookup Zones also created for the 10.0.0.0/24 subnet.

![DNS Manager showing corp.gmbh forward zone with all A records, CNAME aliases and the full zone tree including Reverse Lookup Zones](screenshots/module2-dns-manager-06.png)

Right-clicked DC01 in DNS Manager, Properties, Forwarders tab. Both forwarders showing: 8.8.8.8 resolving to dns.google and 1.1.1.1 resolving to one.one.one.one.

![DNS Manager DC01 Properties Forwarders tab showing 8.8.8.8 dns.google and 1.1.1.1 one.one.one.one](screenshots/module2-dns-forwarders-07.png)

### 🟦 Step 5: Configure DHCP

Created `C:\CorpLab\Setup-DHCP.ps1` and ran it:

```powershell
.\Setup-DHCP.ps1
```

The script installed the DHCP Server role, authorized it in Active Directory, created scope `CorpNet-LAN` for range `10.0.0.100` to `10.0.0.200` with an 8 hour lease, excluded `10.0.0.1` to `10.0.0.50` for static server IPs, set DNS server option to `10.0.0.4` and domain name to `corp.gmbh`, and added a reservation for LINUX01 at `10.0.0.6`.

There was a warning about no static IP addresses found on the computer. This is a known Azure behaviour and does not affect DHCP functionality. The scope still created and activated correctly.

Output showed `DHCP configured successfully` in green, followed by the scope table: ScopeId `10.0.0.0`, SubnetMask `255.255.255.0`, Name `CorpNet-LAN`, State `Active`, StartRange `10.0.0.100`, EndRange `10.0.0.200`, LeaseDuration `08:00:00`.

![PowerShell showing DHCP configured successfully with scope table showing CorpNet-LAN Active 10.0.0.100 to 10.0.0.200](screenshots/module2-dhcp-08.png)

Then opened DHCP Manager to verify:

```powershell
dhcpmgmt.msc
```

DHCP Manager showed the full scope tree under `dc01.corp.gmbh`: IPv4, Scope [10.0.0.0] CorpNet-LAN, with Address Pool, Address Leases, Reservations containing `[10.0.0.6] LINUX01`, Scope Options, and Policies. The Scope Options panel on the right confirmed option 006 DNS Servers set to `10.0.0.4` and option 015 DNS Domain Name set to `corp.gmbh`.

![DHCP Manager showing full scope tree with LINUX01 reservation at 10.0.0.6 and scope options showing DNS server 10.0.0.4 and domain corp.gmbh](screenshots/module2-dhcp-manager-09.png)

### 🟦 Step 6: Build the full AD structure

Created `C:\CorpLab\Setup-ADStructure.ps1` and ran it:

```powershell
.\Setup-ADStructure.ps1
```

The script ran for about 3 to 4 minutes. While it ran, the output streamed each creation in real time.

The script built:
- **18 Organizational Units** with German department names: CORP, Benutzer, IT, Vertrieb, Buchhaltung, Personal, Geschaeftsleitung, Entwicklung, Marketing, Extern, Computer, Workstations, Laptops, Server, Gruppen, ServiceAccounts, Konferenzraeume, Deaktiviert
- **32 security groups**: department groups (GRP-Dept-*), file share groups (GRP-FileShare-*), IT support tiers GRP-IT-L1-Support / GRP-IT-L2-Admin / GRP-IT-L3-Infrastructure, application groups (GRP-App-ERP, GRP-App-CRM, GRP-App-GitLab, GRP-App-Jira, GRP-App-Office365), printer groups, and project groups
- **52 user accounts** across 8 departments with realistic German names, correct group memberships, home directory paths, and forced password change at first logon

When complete, the terminal showed the summary: `AD STRUCTURE SETUP COMPLETE`, Organizational Units: 18, Security Groups: 32, User Accounts: 52, and the log file path `C:\Setup\Logs\AD-Setup-2026-04-18-1727.log`.

![Setup-ADStructure.ps1 completing showing AD STRUCTURE SETUP COMPLETE with counts of 18 OUs, 32 groups, 52 users and log file path](screenshots/module2-ads-strucuring-10.png)

### 🟦 Step 7: Verify AD structure in ADUC

Opened ADUC to check the structure visually. The left tree showed the full OU hierarchy exactly as designed: CORP at the top, then Benutzer with all department sub-OUs (Buchhaltung, Entwicklung, Extern, Geschaeftsleitung, IT, Marketing, Personal, Vertrieb), then Computer with Workstations/Laptops/Server, then Deaktiviert, Gruppen, Konferenzraeume, and ServiceAccounts.

![ADUC showing full OU tree with all 18 OUs including Gruppen selected and the complete left panel hierarchy visible](screenshots/module2-aduc-ou-tree-10.png)

Clicked the IT OU to verify users were created correctly in the right department. Showed 7 users: Daniel Bauer, Florian Koenig, Kevin Wagner, Lisa Schmidt, Petra Schulz, Sabine Lehmann, Thomas Mueller. All matching the script's IT department definition.

![ADUC IT OU showing 7 users: Daniel Bauer, Florian Koenig, Kevin Wagner, Lisa Schmidt, Petra Schulz, Sabine Lehmann, Thomas Mueller](screenshots/module2-aduc-IT-12.png)

Clicked Vertrieb OU. Showed 10 users: Anna Becker, Christian Roth, Julia Weber, Katharina Frank, Markus Lange, Melanie Seidel, Nadine Schubert, Patrick Huber, Stefan Hoffmann, Tobias Berger.

![ADUC Vertrieb OU showing 10 users including Anna Becker, Stefan Hoffmann and others from the sales department](screenshots/module2-aduc-vertrieb-11.png)

Clicked Gruppen OU to check the security groups. Showed all groups created with their German descriptions: GRP-App-CRM with "CRM-System Zugriff", GRP-App-ERP, GRP-App-GitLab, GRP-App-Jira, GRP-App-Office365, all department groups, all file share groups, and the IT tier groups GRP-IT-L1-Support with "L1 Helpdesk: password re...", GRP-IT-L2-Admin with "L2 Admin: GPO, DHCP, D...", GRP-PrinterBW and GRP-PrinterColor all visible.

![ADUC Gruppen OU showing security groups list including GRP-App-*, GRP-Dept-*, GRP-FileShare-* and GRP-IT-L1-Support through L3 with German descriptions](screenshots/module2-aduc-groups-13.png)

### 🟦 Step 8: Check the log file

Opened the log file that the script wrote to `C:\Setup\Logs\AD-Setup-2026-04-18-1727.log` in Notepad to verify everything completed without errors.

The log showed every action timestamped. Starting from 17:27:48, it logged `Starting AD structure setup for CORP GmbH`, then every OU creation with `[SUCCESS]` prefix: CORP, Benutzer, IT, Vertrieb, Buchhaltung, Personal, Geschaeftsleitung, Entwicklung, Marketing, Extern, Computer, Workstations, Laptops, Server, Gruppen, ServiceAccounts, Konferenzraeume, Deaktiviert. Then all 32 groups: GRP-Dept-IT, GRP-Dept-Vertrieb, GRP-Dept-Buchhaltung, GRP-Dept-Personal, GRP-Dept-GF, GRP-Dept-Entwicklung, GRP-Dept-Marketing, GRP-Dept-Extern, GRP-FileShare-Allgemein, GRP-FileShare-IT, GRP-FileShare-Vertrieb, GRP-FileShare-Buchhaltung, GRP-FileShare-Personal, and continuing through all groups.

![Log file open in Notepad showing timestamped SUCCESS entries for all 18 OUs and beginning of 32 security groups](screenshots/module2-adstructure-logs1-14.png)

Scrolled down in the log to see the user creation section and the final summary. The log showed all users being created with `[SUCCESS]` entries including the Entwicklung department users (Werner Schwarz, Sebastian Klein, Nina Wolf, Max Schaefer, Lena Zimmermann, Oliver Kruse, Tanja Fuchs, Philipp Lorenz, Carolin Beck), then Marketing users (Stefanie Meier, Jan Schmitt, Verena Neumann, Alexander Keller, Franziska Haas, Lukas Schreiber), then Extern users (Alex Novak, Maria Santos, Pierre Dupont, Ahmed Hassan, Yuki Tanaka, James Wilson, Olga Petrov, Carlos Rivera). Final log entries confirmed the summary: Organizational Units: 18, Security Groups: 32, User Accounts: 52.

![Log file showing final user creation entries for Extern department and the summary showing 18 OUs, 32 groups, 52 users](screenshots/module2-adstructure-logs2-15.png)

No errors anywhere in the log. Module 2 completed successfully. The Issue #5 was resolved completely.

---


<details>
  <summary> Earlier Option: Local Deployment (VirtualBox)</summary>
    Originally planned it, but I discontinued it due to host RAM constraints.

    ### Created the VMs
    Downloaded and installed VirtualBox from virtualbox.org. Created three VMs:

    - DC01: Windows Server 2025 Eval ISO
    - CLIENT01: Windows 11 Eval ISO
    - LINUX01: Ubuntu Server 22.04 ISO

    Note: It is better to install VirtualBox Extension Pack which can save time later and it is great for IT Home Labs which can provide capabilities, used by IT Professionals everyday.

    Set each VM to use an "Internal Network" adapter (name it "CorpNet"). DC01 also gets a NAT adapter for internet access during setup.
</details>

