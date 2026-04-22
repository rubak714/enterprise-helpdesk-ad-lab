# Network Drive Mapping via GPO

Maps department shares automatically at user logon.

## Drive Mappings
| Drive | Share Path | Target Group |
|-------|-----------|--------------|
| H: | \\SRV01\Home$\%username% | All domain users |
| S: | \\SRV01\Allgemein | GRP-FileShare-Allgemein |
| V: | \\SRV01\Vertrieb | GRP-Dept-Vertrieb |
| B: | \\SRV01\Buchhaltung | GRP-Dept-Buchhaltung |

## GPO Path
User Configuration > Preferences > Windows Settings > Drive Maps

## Notes
- Uses Item-Level Targeting to filter by security group
- Reconnect option enabled for persistent mapping
- Requires logoff/logon to apply (not just gpupdate)