# Enterprise Helpdesk and Active Directory Lab

A home lab environment simulating a small German company's IT infrastructure. I built this to get hands-on experience with Active Directory, Group Policy, and the kind of support tasks that come up every day in L1-L3 helpdesk work.

*Note on Infrastructure:* Originally designed for VirtualBox, this lab was migrated to **Microsoft Azure** to bypass local hardware RAM limitations (16GB) and ensure high performance for Windows 11 and Server 2025.

## Why I built this
I have been helping family and friends with IT issues for years - password
resets, Wi-Fi troubleshooting, printer problems, setting up new laptops and system optimization for better speed and battery life etc. I also helped my German landlord set up their router, new mobile phone setup and fix mobile issues on multiple occasions. But none of that shows up on a CV.

So I decided to build the same kind of 'simulated' environment that a real company would have, document everything properly and show that I can help company and it's people with support work and administration related tasks systematically and not just 'I fixed my friend's laptop.'

## What is in here

This lab simulates "CORP GmbH", which is a fictional German company with about 50 employees across five departments. The infrastructure includes:

- A Windows Server 2025 domain controller (named as - DC01) running AD DS, DNS and DHCP
- A Windows 11 workstation (named as - CLIENT01) joined to the domain
- An Ubuntu 22.04 server (named as - LINUX01) joined to AD via realmd/SSSD

## Why is this lab Important?

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

## How to set up this lab from scratch
*Update:* The infrastructure is now built inside an Azure Virtual Network (VNet) named CorpNet, consisting of:

### Created the VMs

- DC01 (Windows Server 2025): The "Brain" of the company. Domain Controller, DNS, and DHCP.
- CLIENT01 (Windows 11): An employee workstation joined to the corp.gmbh domain.
- LINUX01 (Ubuntu 22.04): A Linux server integrated into the AD environment using realmd/SSSD.

## Current Option: Cloud Deployment (Microsoft Azure)
To ensure the lab runs smoothly without slowing down my physical laptop, I used the following Azure resources:

- Virtual Network: 10.0.0.0/16 (Internal subnet for secure VM communication).

### VM Sizing:
- DC01: Standard_B2als_v2 - 2vcpus, 4GiB memory - Windows Server *2025* Datacenter: Azure Edition - x64 Gen2
- CLIENT01: Standard_ 
- LINUX01: Standard_ 

### Cost Management: 
Configured Auto-shutdown schedules to preserve Azure credits.

## Earlier Option: Local Deployment (VirtualBox)
Originally planned it, but I discontinued it due to host RAM constraints.

### Created the VMs
Downloaded and installed VirtualBox from virtualbox.org. Created three VMs:

- DC01: Windows Server 2022 Eval ISO
- CLIENT01: Windows 11 Eval ISO
- LINUX01: Ubuntu Server 22.04 ISO

*Note:* It is better to install VirtualBox Extension Pack which can save time later and it is great for IT Home Labs which can provide capabilities, used by IT Professionals everyday.

Set each VM to use an "Internal Network" adapter (name it "CorpNet"). DC01 also gets a NAT adapter for internet access during setup.