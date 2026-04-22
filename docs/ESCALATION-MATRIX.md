\# Escalation Matrix - CORP GmbH IT Support



\## Escalation Flow



```

User reports issue

&#x20;   |

&#x20;   v

L1 Support (SLA: 15 min response, 1h resolution)

|-- Resolved? --> Close ticket, document solution

|-- Cannot resolve? --> Escalate to L2

&#x20;       |

&#x20;       v

&#x20;   L2 Admin (SLA: 1h response, 4h resolution)

&#x20;   |-- Resolved? --> Close ticket, document + RCA if needed

&#x20;   |-- Infrastructure issue? --> Escalate to L3

&#x20;   |-- Security issue? --> Escalate to L3 + notify management

&#x20;           |

&#x20;           v

&#x20;       L3 Infrastructure (SLA: 1h response, 24h resolution)

&#x20;       |-- Resolved? --> Close ticket, RCA mandatory

&#x20;       |-- Vendor issue? --> Open vendor ticket, track externally

```



\## Priority Matrix



| Priority | Impact | Urgency | Examples | Response SLA |

|----------|--------|---------|----------|-------------|

| Critical | Entire company affected | Work stopped | DC down, email down, network outage | 15 min |

| High | Department affected | Work degraded | Printer down for floor, shared drive inaccessible | 30 min |

| Medium | Single user affected | Work slowed | Software crash, slow performance | 1 hour |

| Low | Minor inconvenience | Workaround exists | Desktop shortcut missing, font request | 4 hours |



\## Contact List



| Level | Name | Phone | Email |

|-------|------|-------|-------|

| L1 | Kevin Wagner | ext. 100 | kevin.wagner@corp.gmbh |

| L2 | Lisa Schmidt | ext. 101 | lisa.schmidt@corp.gmbh |

| L3 | Thomas Mueller | ext. 102 | thomas.mueller@corp.gmbh |

