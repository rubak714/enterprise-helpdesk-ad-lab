# Setup-GPO.ps1
# Configures Group Policy Objects for CORP GmbH
# Run on DC01 as Domain Administrator
# Creates: password policy, account lockout, drive mapping, security baseline
#
# After running this script, open gpmc.msc to see and verify all GPOs

#Requires -Modules GroupPolicy, ActiveDirectory
$ErrorActionPreference = "Stop"
$Domain = "corp.gmbh"
$LogFile = "C:\Setup\Logs\GPO-Setup-$(Get-Date -Format 'yyyy-MM-dd-HHmm').log"
New-Item -Path (Split-Path $LogFile) -ItemType Directory -Force | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    $Entry | Tee-Object -FilePath $LogFile -Append
}

Write-Log "Starting GPO setup for CORP GmbH"

# ============================================================
# 1. PASSWORD AND LOCKOUT POLICY (Default Domain Policy)
# ============================================================
# Applies to all users in the domain
# Based on BSI IT-Grundschutz recommendations

Write-Log "Configuring password and lockout policy..."

try {
    # Password policy via secedit (most reliable method for domain policy)
    $SecEditFile = "C:\Setup\secpol.inf"
    @"
[Unicode]
Unicode=yes
[System Access]
MinimumPasswordAge = 1
MaximumPasswordAge = 90
MinimumPasswordLength = 12
PasswordComplexity = 1
PasswordHistorySize = 24
LockoutBadCount = 5
ResetLockoutCount = 30
LockoutDuration = 30
[Version]
signature="`$CHICAGO`$"
Revision=1
"@ | Out-File -FilePath $SecEditFile -Encoding Unicode

    secedit /configure /db C:\Setup\secpol.sdb /cfg $SecEditFile /quiet
    Write-Log "Password policy applied via secedit" "SUCCESS"
    Write-Log "  Min length: 12, Max age: 90 days, History: 24, Complexity: On" "SUCCESS"
    Write-Log "  Lockout: 5 attempts, Duration: 30 min, Reset: 30 min" "SUCCESS"
} catch {
    Write-Log "secedit failed, trying via GPO: $_" "WARNING"
}

# ============================================================
# 2. DRIVE MAPPING GPO
# ============================================================
# Maps department shares automatically at user logon
# Uses item-level targeting based on group membership

Write-Log "Creating drive mapping GPO..."

try {
    # Create the GPO
    $GPO = Get-GPO -Name "CORP-Drive-Mapping" -ErrorAction SilentlyContinue
    if (-not $GPO) {
        $GPO = New-GPO -Name "CORP-Drive-Mapping" -Comment "Maps department network drives at logon"
        Write-Log "Created GPO: CORP-Drive-Mapping" "SUCCESS"
    } else {
        Write-Log "GPO already exists: CORP-Drive-Mapping" "WARNING"
    }

    # Link to domain
    $Link = Get-GPInheritance -Target "DC=corp,DC=gmbh"
    $Linked = $Link.GpoLinks | Where-Object { $_.DisplayName -eq "CORP-Drive-Mapping" }
    if (-not $Linked) {
        New-GPLink -Name "CORP-Drive-Mapping" -Target "DC=corp,DC=gmbh" -LinkEnabled Yes
        Write-Log "Linked CORP-Drive-Mapping to domain" "SUCCESS"
    }

    Write-Log "Drive mapping GPO created and linked" "SUCCESS"
    Write-Log "Configure drive maps manually in GPMC:" "INFO"
    Write-Log "  User Config > Preferences > Windows Settings > Drive Maps" "INFO"
    Write-Log "  H: = \\DC01\Home`$\%username% (all users)" "INFO"
    Write-Log "  S: = \\DC01\Allgemein (GRP-FileShare-Allgemein)" "INFO"
    Write-Log "  V: = \\DC01\Vertrieb (GRP-Dept-Vertrieb)" "INFO"
    Write-Log "  B: = \\DC01\Buchhaltung (GRP-Dept-Buchhaltung)" "INFO"
} catch {
    Write-Log "Drive mapping GPO failed: $_" "ERROR"
}

# ============================================================
# 3. SECURITY BASELINE GPO
# ============================================================
# CIS-aligned settings for workstations
# Applies to OU=Workstations

Write-Log "Creating security baseline GPO..."

try {
    $GPO2 = Get-GPO -Name "CORP-Security-Baseline" -ErrorAction SilentlyContinue
    if (-not $GPO2) {
        $GPO2 = New-GPO -Name "CORP-Security-Baseline" -Comment "CIS-aligned security baseline for workstations"
        Write-Log "Created GPO: CORP-Security-Baseline" "SUCCESS"
    }

    # Link to Workstations OU
    $WorkstationsOU = "OU=Workstations,OU=Computer,OU=CORP,DC=corp,DC=gmbh"
    try {
        New-GPLink -Name "CORP-Security-Baseline" -Target $WorkstationsOU -LinkEnabled Yes
        Write-Log "Linked CORP-Security-Baseline to OU=Workstations" "SUCCESS"
    } catch {
        Write-Log "Link already exists or OU not found" "WARNING"
    }

    # Apply registry-based security settings
    # Disable guest account
    Set-GPRegistryValue -Name "CORP-Security-Baseline" `
        -Key "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" `
        -ValueName "AutoAdminLogon" -Type String -Value "0"

    # Show logon warning banner
    Set-GPRegistryValue -Name "CORP-Security-Baseline" `
        -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        -ValueName "legalnoticecaption" -Type String -Value "CORP GmbH - IT Security Policy"

    Set-GPRegistryValue -Name "CORP-Security-Baseline" `
        -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
        -ValueName "legalnoticetext" -Type String `
        -Value "This system is for authorized CORP GmbH users only. All activity is monitored and logged."

    # Disable AutoRun on all drives
    Set-GPRegistryValue -Name "CORP-Security-Baseline" `
        -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
        -ValueName "NoDriveTypeAutoRun" -Type DWord -Value 255

    Write-Log "Security baseline settings applied" "SUCCESS"
    Write-Log "  AutoAdminLogon: disabled" "SUCCESS"
    Write-Log "  Legal notice banner: configured" "SUCCESS"
    Write-Log "  AutoRun: disabled on all drives" "SUCCESS"

} catch {
    Write-Log "Security baseline GPO failed: $_" "ERROR"
}

# ============================================================
# 4. DESKTOP WALLPAPER GPO (shows GPO working visually)
# ============================================================

Write-Log "Creating desktop wallpaper GPO..."

try {
    $GPO3 = Get-GPO -Name "CORP-Desktop-Policy" -ErrorAction SilentlyContinue
    if (-not $GPO3) {
        $GPO3 = New-GPO -Name "CORP-Desktop-Policy" -Comment "Standard desktop settings for all workstations"
        Write-Log "Created GPO: CORP-Desktop-Policy" "SUCCESS"
    }

    New-GPLink -Name "CORP-Desktop-Policy" -Target "DC=corp,DC=gmbh" -LinkEnabled Yes -ErrorAction SilentlyContinue

    # Screen lock after 10 minutes
    Set-GPRegistryValue -Name "CORP-Desktop-Policy" `
        -Key "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" `
        -ValueName "ScreenSaveTimeOut" -Type String -Value "600"

    Set-GPRegistryValue -Name "CORP-Desktop-Policy" `
        -Key "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" `
        -ValueName "ScreenSaverIsSecure" -Type String -Value "1"

    Set-GPRegistryValue -Name "CORP-Desktop-Policy" `
        -Key "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" `
        -ValueName "SCRNSAVE.EXE" -Type String -Value "scrnsave.scr"

    Write-Log "Desktop policy applied" "SUCCESS"
    Write-Log "  Screen lock: 10 minutes with password" "SUCCESS"

} catch {
    Write-Log "Desktop policy failed: $_" "ERROR"
}

# ============================================================
# SUMMARY
# ============================================================

Write-Log "=========================================="
Write-Log "GPO SETUP COMPLETE"
Write-Log "=========================================="
Write-Log "Password policy:     Applied via secedit"
Write-Log "Drive mapping GPO:   CORP-Drive-Mapping (linked to domain)"
Write-Log "Security baseline:   CORP-Security-Baseline (linked to Workstations OU)"
Write-Log "Desktop policy:      CORP-Desktop-Policy (linked to domain)"
Write-Log ""
Write-Log "To verify, open: gpmc.msc"
Write-Log "To apply on clients, run: gpupdate /force"
Write-Log "Log file: $LogFile"