# Software Deployment via GPO

> Status: Planned configuration. MSI hosting on a dedicated file server
> is a prerequisite. Planned for when srv01 is provisioned.

## Deployed Software
| Application | Method | Target |
|-------------|--------|--------|
| 7-Zip | MSI assignment | All workstations |
| Notepad++ | MSI assignment | All workstations |
| Adobe Reader | MSI assignment | All workstations |
| Visual Studio Code | Startup script | GRP-Dept-Entwicklung |

## GPO Path
Computer Configuration > Policies > Software Settings > Software Installation

## Notes
- MSI files stored on \\DC01\NETLOGON\Software\
- Assigned (not published) = installs automatically
- Test on pilot group before full deployment