# BitLocker Drive Encryption Policy

> Status: Planned configuration. Not yet implemented in this lab environment.
> Would be applied to OU=Laptops once physical or Hyper-V laptop VMs are added.

## Settings
| Setting | Value |
|---------|-------|
| Require BitLocker on OS drive | Enabled |
| Encryption method | XTS-AES 256-bit |
| Recovery key backup | To Active Directory |
| Require PIN at startup | Enabled (6-digit minimum) |

## GPO Path
Computer Configuration > Administrative Templates > Windows Components > BitLocker

## Target
Applied to: OU=Laptops,OU=Computer,OU=CORP

## Notes
- Only applied to laptops (mobile devices at higher theft risk)
- Recovery keys stored in AD — viewable by L2+ support
- Users set their own PIN during initial encryption