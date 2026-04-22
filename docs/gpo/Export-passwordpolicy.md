\# Password and Account Lockout Policy



\## Password Policy

| Setting | Value | Reason |

|---------|-------|--------|

| Minimum length | 12 characters | BSI recommendation |

| Complexity | Enabled | Upper, lower, number, special |

| Maximum age | 90 days | Company policy |

| Minimum age | 1 day | Prevent cycling |

| History | 24 passwords | Prevent reuse |



\## Account Lockout Policy

| Setting | Value | Reason |

|---------|-------|--------|

| Threshold | 5 invalid attempts | Balance security and usability |

| Duration | 30 minutes | Auto-unlock after 30 min |

| Reset counter | 30 minutes | Aligns with lockout duration |



\## How to apply

```powershell

\# These settings are configured via Default Domain Policy GPO

\# Edit with: gpmc.msc > corp.local > Default Domain Policy

```

