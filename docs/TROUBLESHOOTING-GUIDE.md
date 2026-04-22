# Troubleshooting Decision Trees

## User Cannot Log In

```
User cannot log in
    |
    +--> Is the account locked? (check with Get-ADUser -Properties LockedOut)
    |    YES --> Run Unlock-ADAccount.ps1, check lockout source
    |    NO  |
    |        +--> Is the password expired? (check PasswordLastSet)
    |        |    YES --> Run Reset-UserPassword.ps1
    |        |    NO  |
    |        |        +--> Is the account disabled?
    |        |        |    YES --> Check with HR, re-enable if authorized
    |        |        |    NO  |
    |        |        |        +--> Can the workstation reach the DC?
    |        |        |             NO  --> Check network, DNS (nslookup corp.gmbh)
    |        |        |             YES --> Check Event Viewer on DC for auth errors
```

## Cannot Access Shared Drive

```
User cannot access \srv01\ShareName
    |
    +--> Can user ping srv01? (ping srv01.corp.gmbh)
    |    NO  --> DNS or network issue, check DNS settings
    |    YES |
    |        +--> Is user in the correct security group?
    |        |    (Get-ADGroupMember "GRP-FileShare-ShareName")
    |        |    NO  --> Add user to group, user must log off/on
    |        |    YES |
    |        |        +--> Check NTFS permissions on share folder
    |        |        |    (Get-ACL \srv01\ShareName | Format-List)
    |        |        +--> Check SMB share permissions
    |        |             (Get-SmbShareAccess -Name ShareName)
```

## Printer Not Working

```
User cannot print
    |
    +--> Is the printer showing as offline?
    |    YES --> Check physical printer (paper, toner, jammed, powered on)
    |    NO  |
    |        +--> Are there stuck jobs in the queue?
    |        |    YES --> Clear print queue:
    |        |           net stop spooler && del /Q %systemroot%\system32\spool\printers\* && net start spooler
    |        |    NO  |
    |        |        +--> Can you ping the printer IP?
    |        |             NO  --> Network issue (check cable, switch port, IP config)
    |        |             YES --> Reinstall printer driver
```

## VPN Not Connecting

```
VPN connection fails
    |
    +--> Does the user have WireGuard client installed?
    |    NO  --> Install from wireguard.com/install
    |    YES |
    |        +--> Is the config file loaded?
    |        |    NO  --> Import config from DC01 VPN-Configs folder
    |        |    YES |
    |        |        +--> Check WireGuard handshake
    |        |        |    (wg show - look for "latest handshake")
    |        |        |    NO handshake --> Firewall blocking UDP 51820?
    |        |        |    Handshake OK |
    |        |        |                 +--> Can reach internal DNS?
    |        |        |                      NO  --> Check split DNS config
    |        |        |                      YES --> VPN working, issue is elsewhere
```