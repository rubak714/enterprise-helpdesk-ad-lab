#Requires -Modules ActiveDirectory
$ErrorActionPreference = "Stop"
$Domain = (Get-ADDomain).DistinguishedName
$LogFile = "C:\Setup\Logs\AD-Setup-$(Get-Date -Format 'yyyy-MM-dd-HHmm').log"
New-Item -Path (Split-Path $LogFile) -ItemType Directory -Force | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    $Entry | Tee-Object -FilePath $LogFile -Append
}

Write-Log "Starting AD structure setup for CORP GmbH"
Write-Log "Domain: $Domain"

$OUs = @(
    @{ Name = "CORP";               Path = $Domain }
    @{ Name = "Benutzer";           Path = "OU=CORP,$Domain" }
    @{ Name = "IT";                 Path = "OU=Benutzer,OU=CORP,$Domain" }
    @{ Name = "Vertrieb";           Path = "OU=Benutzer,OU=CORP,$Domain" }
    @{ Name = "Buchhaltung";        Path = "OU=Benutzer,OU=CORP,$Domain" }
    @{ Name = "Personal";           Path = "OU=Benutzer,OU=CORP,$Domain" }
    @{ Name = "Geschaeftsleitung";  Path = "OU=Benutzer,OU=CORP,$Domain" }
    @{ Name = "Entwicklung";        Path = "OU=Benutzer,OU=CORP,$Domain" }
    @{ Name = "Marketing";          Path = "OU=Benutzer,OU=CORP,$Domain" }
    @{ Name = "Extern";             Path = "OU=Benutzer,OU=CORP,$Domain" }
    @{ Name = "Computer";           Path = "OU=CORP,$Domain" }
    @{ Name = "Workstations";       Path = "OU=Computer,OU=CORP,$Domain" }
    @{ Name = "Laptops";            Path = "OU=Computer,OU=CORP,$Domain" }
    @{ Name = "Server";             Path = "OU=Computer,OU=CORP,$Domain" }
    @{ Name = "Gruppen";            Path = "OU=CORP,$Domain" }
    @{ Name = "ServiceAccounts";    Path = "OU=CORP,$Domain" }
    @{ Name = "Konferenzraeume";    Path = "OU=CORP,$Domain" }
    @{ Name = "Deaktiviert";        Path = "OU=CORP,$Domain" }
)

Write-Log "Creating 18 Organizational Units..."
foreach ($OU in $OUs) {
    try {
        $Exists = Get-ADOrganizationalUnit -Filter "Name -eq '$($OU.Name)'" `
            -SearchBase $OU.Path -SearchScope OneLevel -ErrorAction SilentlyContinue
        if (-not $Exists) {
            New-ADOrganizationalUnit -Name $OU.Name -Path $OU.Path `
                -ProtectedFromAccidentalDeletion $true
            Write-Log "Created OU: $($OU.Name)" "SUCCESS"
        } else {
            Write-Log "OU already exists: $($OU.Name)" "WARNING"
        }
    } catch {
        Write-Log "Failed to create OU $($OU.Name): $_" "ERROR"
    }
}

$GroupsOU = "OU=Gruppen,OU=CORP,$Domain"
$Groups = @(
    @{ Name = "GRP-Dept-IT";                 Desc = "IT-Abteilung" }
    @{ Name = "GRP-Dept-Vertrieb";           Desc = "Vertriebsabteilung" }
    @{ Name = "GRP-Dept-Buchhaltung";        Desc = "Buchhaltung" }
    @{ Name = "GRP-Dept-Personal";           Desc = "Personalabteilung" }
    @{ Name = "GRP-Dept-GF";                 Desc = "Geschaeftsfuehrung" }
    @{ Name = "GRP-Dept-Entwicklung";        Desc = "Entwicklungsabteilung" }
    @{ Name = "GRP-Dept-Marketing";          Desc = "Marketingabteilung" }
    @{ Name = "GRP-Dept-Extern";             Desc = "Externe Mitarbeiter" }
    @{ Name = "GRP-FileShare-Allgemein";     Desc = "Zugriff auf allgemeinen Share" }
    @{ Name = "GRP-FileShare-IT";            Desc = "Zugriff auf IT-Share" }
    @{ Name = "GRP-FileShare-Vertrieb";      Desc = "Zugriff auf Vertrieb-Share" }
    @{ Name = "GRP-FileShare-Buchhaltung";   Desc = "Zugriff auf Buchhaltung-Share" }
    @{ Name = "GRP-FileShare-Personal";      Desc = "Zugriff auf Personal-Share" }
    @{ Name = "GRP-FileShare-GF";            Desc = "Zugriff auf GF-Share" }
    @{ Name = "GRP-FileShare-Entwicklung";   Desc = "Zugriff auf Entwicklung-Share" }
    @{ Name = "GRP-FileShare-Marketing";     Desc = "Zugriff auf Marketing-Share" }
    @{ Name = "GRP-IT-L1-Support";           Desc = "L1 Helpdesk: password reset, account unlock" }
    @{ Name = "GRP-IT-L2-Admin";             Desc = "L2 Admin: GPO, DHCP, DNS, server management" }
    @{ Name = "GRP-IT-L3-Infrastructure";    Desc = "L3 Infrastructure: DC, AD, backup, DR" }
    @{ Name = "GRP-App-ERP";                 Desc = "ERP-System Zugriff" }
    @{ Name = "GRP-App-CRM";                 Desc = "CRM-System Zugriff" }
    @{ Name = "GRP-App-Jira";                Desc = "Jira Projektmanagement Zugriff" }
    @{ Name = "GRP-App-GitLab";              Desc = "GitLab Repository Zugriff" }
    @{ Name = "GRP-App-Office365";           Desc = "Microsoft 365 Lizenz" }
    @{ Name = "GRP-VPN-Users";               Desc = "VPN-Zugang fuer Fernzugriff" }
    @{ Name = "GRP-RemoteDesktop";           Desc = "Remotedesktop-Zugang" }
    @{ Name = "GRP-PrinterColor";            Desc = "Farbdrucker Etage 1" }
    @{ Name = "GRP-PrinterColor-E2";         Desc = "Farbdrucker Etage 2" }
    @{ Name = "GRP-PrinterBW";               Desc = "SW-Drucker alle Etagen" }
    @{ Name = "GRP-Projekt-WebRelaunch";     Desc = "Projektteam Website-Relaunch" }
    @{ Name = "GRP-Projekt-ERP-Migration";   Desc = "Projektteam ERP-Migration" }
    @{ Name = "GRP-Projekt-ISO27001";        Desc = "Projektteam ISO 27001 Zertifizierung" }
)

Write-Log "Creating 32 Security Groups..."
foreach ($Group in $Groups) {
    try {
        if (-not (Get-ADGroup -Filter "Name -eq '$($Group.Name)'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name $Group.Name -GroupScope Global `
                -GroupCategory Security -Path $GroupsOU -Description $Group.Desc
            Write-Log "Created group: $($Group.Name)" "SUCCESS"
        }
    } catch {
        Write-Log "Failed to create group $($Group.Name): $_" "ERROR"
    }
}

Write-Log "Creating 52 users across 8 departments..."
$DefaultPassword = ConvertTo-SecureString "Welcome2026!" -AsPlainText -Force

$Users = @(
    @{ First="Thomas";    Last="Mueller";     Dept="IT";                Title="IT-Leiter";                Groups=@("GRP-Dept-IT","GRP-IT-L3-Infrastructure","GRP-FileShare-IT","GRP-VPN-Users","GRP-App-Office365","GRP-Projekt-ISO27001") }
    @{ First="Lisa";      Last="Schmidt";     Dept="IT";                Title="L2 Systemadministrator";    Groups=@("GRP-Dept-IT","GRP-IT-L2-Admin","GRP-FileShare-IT","GRP-VPN-Users","GRP-App-Office365") }
    @{ First="Kevin";     Last="Wagner";      Dept="IT";                Title="L1 Helpdesk";               Groups=@("GRP-Dept-IT","GRP-IT-L1-Support","GRP-FileShare-IT","GRP-App-Office365") }
    @{ First="Petra";     Last="Schulz";      Dept="IT";                Title="L1 Helpdesk";               Groups=@("GRP-Dept-IT","GRP-IT-L1-Support","GRP-FileShare-IT","GRP-App-Office365") }
    @{ First="Daniel";    Last="Bauer";       Dept="IT";                Title="L2 Netzwerkadmin";          Groups=@("GRP-Dept-IT","GRP-IT-L2-Admin","GRP-FileShare-IT","GRP-VPN-Users","GRP-App-Office365") }
    @{ First="Sabine";    Last="Lehmann";     Dept="IT";                Title="IT-Security Beauftragter";  Groups=@("GRP-Dept-IT","GRP-IT-L3-Infrastructure","GRP-FileShare-IT","GRP-VPN-Users","GRP-Projekt-ISO27001","GRP-App-Office365") }
    @{ First="Florian";   Last="Koenig";      Dept="IT";                Title="Junior Systemadmin";        Groups=@("GRP-Dept-IT","GRP-IT-L1-Support","GRP-FileShare-IT","GRP-App-Office365") }
    @{ First="Anna";      Last="Becker";      Dept="Vertrieb";          Title="Vertriebsleiterin";         Groups=@("GRP-Dept-Vertrieb","GRP-FileShare-Vertrieb","GRP-FileShare-Allgemein","GRP-App-CRM","GRP-VPN-Users","GRP-App-Office365") }
    @{ First="Stefan";    Last="Hoffmann";    Dept="Vertrieb";          Title="Key Account Manager";       Groups=@("GRP-Dept-Vertrieb","GRP-FileShare-Vertrieb","GRP-FileShare-Allgemein","GRP-App-CRM","GRP-VPN-Users","GRP-App-Office365") }
    @{ First="Julia";     Last="Weber";       Dept="Vertrieb";          Title="Vertriebsmitarbeiterin";    Groups=@("GRP-Dept-Vertrieb","GRP-FileShare-Vertrieb","GRP-FileShare-Allgemein","GRP-App-CRM","GRP-App-Office365") }
    @{ First="Markus";    Last="Lange";       Dept="Vertrieb";          Title="Vertriebsmitarbeiter";      Groups=@("GRP-Dept-Vertrieb","GRP-FileShare-Vertrieb","GRP-FileShare-Allgemein","GRP-App-CRM","GRP-App-Office365") }
    @{ First="Katharina"; Last="Frank";       Dept="Vertrieb";          Title="Inside Sales";              Groups=@("GRP-Dept-Vertrieb","GRP-FileShare-Vertrieb","GRP-FileShare-Allgemein","GRP-App-CRM","GRP-App-Office365") }
    @{ First="Tobias";    Last="Berger";      Dept="Vertrieb";          Title="Aussendienst";              Groups=@("GRP-Dept-Vertrieb","GRP-FileShare-Vertrieb","GRP-FileShare-Allgemein","GRP-App-CRM","GRP-VPN-Users","GRP-App-Office365") }
    @{ First="Nadine";    Last="Schubert";    Dept="Vertrieb";          Title="Vertriebsassistenz";        Groups=@("GRP-Dept-Vertrieb","GRP-FileShare-Vertrieb","GRP-FileShare-Allgemein","GRP-App-CRM","GRP-App-Office365") }
    @{ First="Patrick";   Last="Huber";       Dept="Vertrieb";          Title="Vertriebsmitarbeiter";      Groups=@("GRP-Dept-Vertrieb","GRP-FileShare-Vertrieb","GRP-FileShare-Allgemein","GRP-App-CRM","GRP-App-Office365") }
    @{ First="Melanie";   Last="Seidel";      Dept="Vertrieb";          Title="Pre-Sales Beraterin";       Groups=@("GRP-Dept-Vertrieb","GRP-FileShare-Vertrieb","GRP-FileShare-Allgemein","GRP-App-CRM","GRP-VPN-Users","GRP-App-Office365") }
    @{ First="Christian"; Last="Roth";        Dept="Vertrieb";          Title="Vertriebsmitarbeiter";      Groups=@("GRP-Dept-Vertrieb","GRP-FileShare-Vertrieb","GRP-FileShare-Allgemein","GRP-App-CRM","GRP-App-Office365") }
    @{ First="Michael";   Last="Fischer";     Dept="Buchhaltung";       Title="Leiter Buchhaltung";        Groups=@("GRP-Dept-Buchhaltung","GRP-FileShare-Buchhaltung","GRP-FileShare-Allgemein","GRP-App-ERP","GRP-App-Office365") }
    @{ First="Sandra";    Last="Koch";        Dept="Buchhaltung";       Title="Buchhalterin";              Groups=@("GRP-Dept-Buchhaltung","GRP-FileShare-Buchhaltung","GRP-FileShare-Allgemein","GRP-App-ERP","GRP-App-Office365") }
    @{ First="Juergen";   Last="Vogel";       Dept="Buchhaltung";       Title="Buchhalter";                Groups=@("GRP-Dept-Buchhaltung","GRP-FileShare-Buchhaltung","GRP-FileShare-Allgemein","GRP-App-ERP","GRP-App-Office365") }
    @{ First="Andrea";    Last="Stein";       Dept="Buchhaltung";       Title="Lohnbuchhalterin";          Groups=@("GRP-Dept-Buchhaltung","GRP-FileShare-Buchhaltung","GRP-FileShare-Allgemein","GRP-App-ERP","GRP-App-Office365") }
    @{ First="Ralf";      Last="Winter";      Dept="Buchhaltung";       Title="Controller";                Groups=@("GRP-Dept-Buchhaltung","GRP-FileShare-Buchhaltung","GRP-FileShare-Allgemein","GRP-App-ERP","GRP-VPN-Users","GRP-App-Office365") }
    @{ First="Birgit";    Last="Baumann";     Dept="Buchhaltung";       Title="Buchhalterin";              Groups=@("GRP-Dept-Buchhaltung","GRP-FileShare-Buchhaltung","GRP-FileShare-Allgemein","GRP-App-ERP","GRP-App-Office365") }
    @{ First="Claudia";   Last="Richter";     Dept="Personal";          Title="Personalleiterin";          Groups=@("GRP-Dept-Personal","GRP-FileShare-Personal","GRP-FileShare-Allgemein","GRP-App-Office365") }
    @{ First="Markus";    Last="Braun";       Dept="Personal";          Title="Personalsachbearbeiter";    Groups=@("GRP-Dept-Personal","GRP-FileShare-Personal","GRP-FileShare-Allgemein","GRP-App-Office365") }
    @{ First="Heike";     Last="Kraus";       Dept="Personal";          Title="Recruiterin";               Groups=@("GRP-Dept-Personal","GRP-FileShare-Personal","GRP-FileShare-Allgemein","GRP-App-Office365") }
    @{ First="Martin";    Last="Engel";       Dept="Personal";          Title="Personalentwickler";        Groups=@("GRP-Dept-Personal","GRP-FileShare-Personal","GRP-FileShare-Allgemein","GRP-App-Office365") }
    @{ First="Hans";      Last="Schneider";   Dept="Geschaeftsleitung"; Title="Geschaeftsfuehrer";         Groups=@("GRP-Dept-GF","GRP-FileShare-GF","GRP-FileShare-Allgemein","GRP-VPN-Users","GRP-RemoteDesktop","GRP-App-Office365") }
    @{ First="Elisabeth"; Last="Hartmann";    Dept="Geschaeftsleitung"; Title="CFO";                       Groups=@("GRP-Dept-GF","GRP-FileShare-GF","GRP-FileShare-Allgemein","GRP-VPN-Users","GRP-RemoteDesktop","GRP-App-Office365","GRP-App-ERP") }
    @{ First="Werner";    Last="Schwarz";     Dept="Geschaeftsleitung"; Title="CTO";                       Groups=@("GRP-Dept-GF","GRP-FileShare-GF","GRP-FileShare-Allgemein","GRP-VPN-Users","GRP-RemoteDesktop","GRP-App-Office365","GRP-App-GitLab") }
    @{ First="Sebastian"; Last="Klein";       Dept="Entwicklung";       Title="Entwicklungsleiter";        Groups=@("GRP-Dept-Entwicklung","GRP-FileShare-Entwicklung","GRP-FileShare-Allgemein","GRP-App-GitLab","GRP-App-Jira","GRP-VPN-Users","GRP-App-Office365","GRP-Projekt-WebRelaunch") }
    @{ First="Nina";      Last="Wolf";        Dept="Entwicklung";       Title="Senior Entwicklerin";       Groups=@("GRP-Dept-Entwicklung","GRP-FileShare-Entwicklung","GRP-FileShare-Allgemein","GRP-App-GitLab","GRP-App-Jira","GRP-VPN-Users","GRP-App-Office365") }
    @{ First="Max";       Last="Schaefer";    Dept="Entwicklung";       Title="Backend Entwickler";        Groups=@("GRP-Dept-Entwicklung","GRP-FileShare-Entwicklung","GRP-FileShare-Allgemein","GRP-App-GitLab","GRP-App-Jira","GRP-App-Office365") }
    @{ First="Lena";      Last="Zimmermann";  Dept="Entwicklung";       Title="Frontend Entwicklerin";     Groups=@("GRP-Dept-Entwicklung","GRP-FileShare-Entwicklung","GRP-FileShare-Allgemein","GRP-App-GitLab","GRP-App-Jira","GRP-App-Office365","GRP-Projekt-WebRelaunch") }
    @{ First="Oliver";    Last="Kruse";       Dept="Entwicklung";       Title="DevOps Engineer";           Groups=@("GRP-Dept-Entwicklung","GRP-FileShare-Entwicklung","GRP-FileShare-Allgemein","GRP-App-GitLab","GRP-App-Jira","GRP-VPN-Users","GRP-App-Office365") }
    @{ First="Tanja";     Last="Fuchs";       Dept="Entwicklung";       Title="QA Testerin";               Groups=@("GRP-Dept-Entwicklung","GRP-FileShare-Entwicklung","GRP-FileShare-Allgemein","GRP-App-GitLab","GRP-App-Jira","GRP-App-Office365") }
    @{ First="Philipp";   Last="Lorenz";      Dept="Entwicklung";       Title="Junior Entwickler";         Groups=@("GRP-Dept-Entwicklung","GRP-FileShare-Entwicklung","GRP-FileShare-Allgemein","GRP-App-GitLab","GRP-App-Jira","GRP-App-Office365") }
    @{ First="Carolin";   Last="Beck";        Dept="Entwicklung";       Title="UX Designerin";             Groups=@("GRP-Dept-Entwicklung","GRP-FileShare-Entwicklung","GRP-FileShare-Allgemein","GRP-App-GitLab","GRP-App-Jira","GRP-App-Office365","GRP-Projekt-WebRelaunch") }
    @{ First="Stefanie";  Last="Meier";       Dept="Marketing";         Title="Marketingleiterin";         Groups=@("GRP-Dept-Marketing","GRP-FileShare-Marketing","GRP-FileShare-Allgemein","GRP-App-Office365","GRP-Projekt-WebRelaunch") }
    @{ First="Jan";       Last="Schmitt";     Dept="Marketing";         Title="Content Manager";           Groups=@("GRP-Dept-Marketing","GRP-FileShare-Marketing","GRP-FileShare-Allgemein","GRP-App-Office365") }
    @{ First="Verena";    Last="Neumann";     Dept="Marketing";         Title="Social Media Managerin";    Groups=@("GRP-Dept-Marketing","GRP-FileShare-Marketing","GRP-FileShare-Allgemein","GRP-App-Office365") }
    @{ First="Alexander"; Last="Keller";      Dept="Marketing";         Title="Grafikdesigner";            Groups=@("GRP-Dept-Marketing","GRP-FileShare-Marketing","GRP-FileShare-Allgemein","GRP-App-Office365","GRP-PrinterColor") }
    @{ First="Franziska"; Last="Haas";        Dept="Marketing";         Title="Event Managerin";           Groups=@("GRP-Dept-Marketing","GRP-FileShare-Marketing","GRP-FileShare-Allgemein","GRP-App-Office365","GRP-VPN-Users") }
    @{ First="Lukas";     Last="Schreiber";   Dept="Marketing";         Title="SEO Spezialist";            Groups=@("GRP-Dept-Marketing","GRP-FileShare-Marketing","GRP-FileShare-Allgemein","GRP-App-Office365") }
    @{ First="Alex";      Last="Novak";       Dept="Extern";            Title="Externer SAP Berater";      Groups=@("GRP-Dept-Extern","GRP-VPN-Users","GRP-App-ERP","GRP-Projekt-ERP-Migration") }
    @{ First="Maria";     Last="Santos";      Dept="Extern";            Title="Externe Entwicklerin";      Groups=@("GRP-Dept-Extern","GRP-VPN-Users","GRP-App-GitLab") }
    @{ First="Pierre";    Last="Dupont";      Dept="Extern";            Title="Externer Auditor";          Groups=@("GRP-Dept-Extern","GRP-VPN-Users","GRP-Projekt-ISO27001") }
    @{ First="Ahmed";     Last="Hassan";      Dept="Extern";            Title="Externer Netzwerktechniker"; Groups=@("GRP-Dept-Extern","GRP-VPN-Users") }
    @{ First="Yuki";      Last="Tanaka";      Dept="Extern";            Title="Externe UX Beraterin";      Groups=@("GRP-Dept-Extern","GRP-VPN-Users","GRP-Projekt-WebRelaunch") }
    @{ First="James";     Last="Wilson";      Dept="Extern";            Title="Externer Security Auditor"; Groups=@("GRP-Dept-Extern","GRP-VPN-Users","GRP-Projekt-ISO27001") }
    @{ First="Olga";      Last="Petrov";      Dept="Extern";            Title="Externe Datenschutzberaterin"; Groups=@("GRP-Dept-Extern","GRP-VPN-Users") }
    @{ First="Carlos";    Last="Rivera";      Dept="Extern";            Title="Externer Cloud Berater";    Groups=@("GRP-Dept-Extern","GRP-VPN-Users") }
)

foreach ($User in $Users) {
    $Sam = "$($User.First.ToLower()).$($User.Last.ToLower())"
    $UPN = "$Sam@corp.gmbh"
    $OU  = "OU=$($User.Dept),OU=Benutzer,OU=CORP,$Domain"
    $DisplayName = "$($User.First) $($User.Last)"

    try {
        if (-not (Get-ADUser -Filter "SamAccountName -eq '$Sam'" -ErrorAction SilentlyContinue)) {
            New-ADUser -Name $DisplayName `
                -GivenName $User.First -Surname $User.Last `
                -SamAccountName $Sam -UserPrincipalName $UPN `
                -Path $OU -Title $User.Title -Department $User.Dept `
                -Company "CORP GmbH" -Office "Berlin" `
                -AccountPassword $DefaultPassword `
                -ChangePasswordAtLogon $true -Enabled $true

            foreach ($GroupName in $User.Groups) {
                Add-ADGroupMember -Identity $GroupName -Members $Sam
            }

            Write-Log "Created user: $DisplayName ($Sam) in $($User.Dept)" "SUCCESS"
        }
    } catch {
        Write-Log "Failed to create user $Sam`: $_" "ERROR"
    }
}

$UserCount = ($Users | Measure-Object).Count
$GroupCount = ($Groups | Measure-Object).Count
$OUCount = ($OUs | Measure-Object).Count

Write-Log "=========================================="
Write-Log "AD STRUCTURE SETUP COMPLETE"
Write-Log "=========================================="
Write-Log "Organizational Units: $OUCount"
Write-Log "Security Groups:      $GroupCount"
Write-Log "User Accounts:        $UserCount"
Write-Log "Log file:             $LogFile"
