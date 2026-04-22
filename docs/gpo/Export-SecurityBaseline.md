# CIS-Aligned Security Baseline

Based on CIS Microsoft Windows Server 2022 Benchmark v1.0

## Key Settings
| Setting | Value | CIS Reference |
|---------|-------|---------------|
| Audit logon events | Success, Failure | 17.5.x |
| Interactive logon message | Company warning banner | 2.3.7.x |
| Network access: restrict anonymous | Enabled | 2.3.10.x |
| Windows Firewall: Domain profile | Enabled | 9.1.x |
| Disable guest account | Enabled | 1.1.x |
| Rename administrator account | corp-admin | 1.1.x |

## Applied via
Computer Configuration > Policies > Windows Settings > Security Settings