# WaveControl Flowcharts (Mermaid)

This document groups all project flowcharts using Mermaid `flowchart` syntax, for direct use in Mermaid-compatible tools.

To improve visual readability, each flowchart uses:
- increased spacing between nodes,
- a consistent palette (start/end, action, decision, result),
- branch structuring that avoids overlapping labels.

---

## 0) High-level app navigation

```mermaid
---
config:
  theme: base
  flowchart:
    nodeSpacing: 44
    rankSpacing: 60
    curve: linear
  themeVariables:
    fontSize: 13px
    lineColor: '#334155'
    primaryTextColor: '#0f172a'
    fontFamily: Inter,Segoe UI,Arial
  layout: fixed
---
flowchart TB
  C["HomeScreen"] --> E["SettingsScreen"] & G["ViewConfigsScreen"] & F["Device monitoring"] & I["MqttControlPage"] & H["ConfigurationScreen"]
  H --> K["Motion config / IR remote management"] & C
    K --> L["IRDeviceDetailScreen"]
    E --> C
    F --> C
    G --> C
    I --> C
    A(["App launch"]) --> C

     C:::action
     E:::action
     G:::action
     F:::action
     I:::action
     H:::action
     K:::action
     L:::action
     A:::start
    classDef start fill:#0ea5e9,stroke:#0369a1,color:#ffffff,stroke-width:2px
    classDef action fill:#e2e8f0,stroke:#64748b,color:#0f172a,stroke-width:1.5px
    classDef decision fill:#fef3c7,stroke:#d97706,color:#78350f,stroke-width:2px
```

---


## 1) Global navigation and startup

```mermaid
graph TD
  %% Start node
  Start([Launch WaveControl app]) --> Home[Home - Main hub]

  %% Top navigation
  Home --> ModeSel[Selected mode]
  Home --> Params[Settings]

  %% Selection logic
  Params --> Choice{Mode selection}

  %% Mode branches
  Choice --> User[User mode]
  Choice --> Tech[Technician mode]
  Choice --> Dev[Developer mode]

  %% User mode actions
  User --> ViewConfig[View configuration]
    User --> Monitor[Monitoring]

  %% Technician mode actions
    Tech --> Monitor
  Tech --> Config[Setup]

  %% Developer mode actions
    Dev --> Config
    Dev --> Test[TEST MQTT]
    Dev --> Monitor

  %% Style (Optional to match the image)
    style Choice fill:#fff,stroke:#333,stroke-width:2px
    style Start fill:#fff,stroke:#333,stroke-width:1px
    style Home fill:#fff,stroke:#333,stroke-width:1px
```

---

## 2) Full MQTT command flow

```mermaid
---
config:
  theme: base
  flowchart:
    nodeSpacing: 40
    rankSpacing: 50
    curve: linear
  themeVariables:
    fontSize: 13px
    lineColor: '#334155'
    primaryTextColor: '#0f172a'
    fontFamily: Inter,Segoe UI,Arial
  layout: dagre
---
flowchart TB
  A["User action"] --> B["UI triggers command"]
  B --> C["MQTT service sends"]
    C --> D["Broker MQTT"]
  D --> E["Device executes"] & G["App receives feedback"]
  E --> F["Device publishes new state"]
    F --> D
  G --> H["Update local state"]
  H --> I["UI refreshed"]

     A:::start
     B:::action
     C:::action
     D:::action
     E:::action
     G:::action
     F:::action
     H:::action
     I:::result
    classDef start fill:#0ea5e9,stroke:#0369a1,color:#ffffff,stroke-width:2px
    classDef action fill:#e2e8f0,stroke:#64748b,color:#0f172a,stroke-width:1.5px
    classDef result fill:#dcfce7,stroke:#16a34a,color:#14532d,stroke-width:2px
```

---

## 3) Network reconnection

```mermaid
%%{init: {'theme':'base','flowchart':{'nodeSpacing':42,'rankSpacing':58,'curve':'linear'},'themeVariables':{'fontSize':'13px','lineColor':'#334155','primaryTextColor':'#0f172a','fontFamily':'Inter,Segoe UI,Arial'}}}%%
flowchart TD
  A[App connected] --> B{Network available?}
  B -->|Yes| C[Nominal operation]
  B -->|No| D[Network loss detected]
  D --> E[MQTT disconnected status]
  E --> F[Connectivity monitoring]
  F --> G{Network restored?}
  G -->|No| F
  G -->|Yes| H[MQTT reconnection attempt]
  H --> I{Success?}
  I -->|Yes| J[Resubscribe to topics]
  J --> K[State resynchronization]
    K --> C
  I -->|No| L[Timed retry]
    L --> H

    classDef start fill:#0ea5e9,stroke:#0369a1,color:#ffffff,stroke-width:2px;
    classDef action fill:#e2e8f0,stroke:#64748b,color:#0f172a,stroke-width:1.5px;
    classDef decision fill:#fef3c7,stroke:#d97706,color:#78350f,stroke-width:2px;
    classDef result fill:#dcfce7,stroke:#16a34a,color:#14532d,stroke-width:2px;
    classDef warning fill:#fee2e2,stroke:#dc2626,color:#7f1d1d,stroke-width:1.8px;

    class A start;
    class D,E,F,H,J,K,L action;
    class B,G,I decision;
    class C result;
```

---



## 5) Wristband configuration workflow

```mermaid
---
config:
  theme: base
  flowchart:
    nodeSpacing: 42
    rankSpacing: 58
    curve: linear
  themeVariables:
    fontSize: 13px
    lineColor: '#334155'
    primaryTextColor: '#0f172a'
    fontFamily: Inter,Segoe UI,Arial
  layout: fixed
---
flowchart TB
  A["Enter Configuration screen"] --> B["Request wristband capabilities"]
  B --> C["Receive capabilities"]
  C --> D["Load existing config"]
  D --> E{"Existing configuration?"}
  E -- Yes --> F["Display"]
  E -- No --> G["Creation wizard"]
  G --> H["Add motion mapping"]
  H --> I["User validation"]
  I --> J["Send via MQTT"]
  J --> K{"Success status?"}
  K -- Yes --> L["Confirmation + reload"]
  K -- No --> M["Error"]
  F --> n1["Button choice"]
  n1 -- Add Config --> H
  n1 -- Infrared --> n2["Infrared management"]

    n1@{ shape: diam}
    n2@{ shape: rect}
     A:::start
     B:::action
     C:::action
     D:::action
     E:::decision
     F:::action
     G:::action
     H:::action
     I:::action
     J:::action
     K:::decision
     L:::result
     M:::warning
     n1:::decision
     n2:::action
    classDef start fill:#0ea5e9,stroke:#0369a1,color:#ffffff,stroke-width:2px
    classDef action fill:#e2e8f0,stroke:#64748b,color:#0f172a,stroke-width:1.5px
    classDef decision fill:#fef3c7,stroke:#d97706,color:#78350f,stroke-width:2px
    classDef result fill:#dcfce7,stroke:#16a34a,color:#14532d,stroke-width:2px
    classDef warning fill:#fee2e2,stroke:#dc2626,color:#7f1d1d,stroke-width:1.8px
```

---


## 6) Incoming message processing

```mermaid
---
config:
  theme: base
  flowchart:
    nodeSpacing: 42
    rankSpacing: 58
    curve: linear
  themeVariables:
    fontSize: 13px
    lineColor: '#334155'
    primaryTextColor: '#0f172a'
    fontFamily: Inter,Segoe UI,Arial
  layout: fixed
---
flowchart TB
  A["Incoming MQTT message"] --> B["Identify topic"]
  B --> C["Parse payload"]
  C --> D{"Valid payload?"}
  D -- Yes --> E["Update local state"]
  D -- No --> F["Log error"]
  E --> G["Notify screens"]
    F --> G
  G --> H["UI refreshed"]

     A:::start
     B:::action
     C:::action
     D:::decision
     E:::action
     F:::warning
     G:::action
     H:::result
    classDef start fill:#0ea5e9,stroke:#0369a1,color:#ffffff,stroke-width:2px
    classDef action fill:#e2e8f0,stroke:#64748b,color:#0f172a,stroke-width:1.5px
    classDef decision fill:#fef3c7,stroke:#d97706,color:#78350f,stroke-width:2px
    classDef result fill:#dcfce7,stroke:#16a34a,color:#14532d,stroke-width:2px
    classDef warning fill:#fee2e2,stroke:#dc2626,color:#7f1d1d,stroke-width:1.8px
```

---

## 7) Workflow for adding an action to an IR remote

```mermaid
---

---
config:
  theme: base
  flowchart:
    nodeSpacing: 42
    rankSpacing: 58
    curve: linear
  themeVariables:
    fontSize: 13px
    lineColor: '#334155'
    primaryTextColor: '#0f172a'
    fontFamily: Inter,Segoe UI,Arial
  layout: fixed
---
flowchart TB
  A["Open remote details"] --> B["Click Add action"]
  B --> C["Enter action name"]
  C --> D{"Valid name?"}
  D -- No --> E["Show input error"]
    E --> C
  D -- Yes --> F["Switch to IR learning mode"]
  F --> G["Request physical button press"]
  G --> H{"IR signal received?"}
  H -- No --> I["Timeout / retry"]
    I --> G
  H -- Yes --> J["Save IR code"]
  J --> K["Publish MQTT update"]
  K --> L{"Confirmation feedback?"}
  L -- No --> M["Failure alert + keep draft"]
  L -- Yes --> N["Refresh actions list"]
  N --> O["Action visible on the remote"]

     A:::start
     B:::action
     C:::action
     D:::decision
     E:::warning
     F:::action
     G:::action
     H:::decision
     I:::warning
     J:::action
     K:::action
     L:::decision
     M:::warning
     N:::action
     O:::result
    classDef start fill:#0ea5e9,stroke:#0369a1,color:#ffffff,stroke-width:2px
    classDef action fill:#e2e8f0,stroke:#64748b,color:#0f172a,stroke-width:1.5px
    classDef decision fill:#fef3c7,stroke:#d97706,color:#78350f,stroke-width:2px
    classDef result fill:#dcfce7,stroke:#16a34a,color:#14532d,stroke-width:2px
    classDef warning fill:#fee2e2,stroke:#dc2626,color:#7f1d1d,stroke-width:1.8px
```

```
## 10) Monitoring workflow

```mermaid
---
config:
  theme: base
  flowchart:
    nodeSpacing: 42
    rankSpacing: 58
    curve: linear
  themeVariables:
    fontSize: 13px
    lineColor: '#334155'
    primaryTextColor: '#0f172a'
    fontFamily: Inter,Segoe UI,Arial
  layout: fixed
---
flowchart TB
  A["Open Monitoring from Home"] --> B["Load device states"]
  B --> C{"Data available?"}
  C -- No --> D["Show empty / disconnected state"]
  C -- Yes --> F["Show device grid"]
  F --> G{"User action?"}
  G -- None --> H["Passive real-time updates"]
    H --> F
    G -- ON/OFF --> I["Send MQTT command"]
  G -- Color/Brightness --> J["Open lamp control"]
    J --> I
  I --> K{"MQTT feedback received?"}
  K -- No --> L["Show delay / retry"]
    L --> I
  K -- Yes --> M["Update local state"]
  M --> N["Refresh device card"]
  N --> O["Status visible and consistent"]
    D --> B

     A:::start
     B:::action
     C:::decision
     D:::warning
     F:::action
     G:::decision
     H:::action
     I:::action
     J:::action
     K:::decision
     L:::warning
     M:::action
     N:::action
     O:::result
    classDef start fill:#0ea5e9,stroke:#0369a1,color:#ffffff,stroke-width:2px
    classDef action fill:#e2e8f0,stroke:#64748b,color:#0f172a,stroke-width:1.5px
    classDef decision fill:#fef3c7,stroke:#d97706,color:#78350f,stroke-width:2px
    classDef result fill:#dcfce7,stroke:#16a34a,color:#14532d,stroke-width:2px
    classDef warning fill:#fee2e2,stroke:#dc2626,color:#7f1d1d,stroke-width:1.8px
```

---

## 11) TEST.MQTT workflow

```mermaid
---
config:
  theme: base
  flowchart:
    nodeSpacing: 42
    rankSpacing: 58
    curve: linear
  themeVariables:
    fontSize: 13px
    lineColor: '#334155'
    primaryTextColor: '#0f172a'
    fontFamily: Inter,Segoe UI,Arial
  layout: fixed
---
flowchart TB
  A["Open TEST.MQTT from Home"] --> B["Initialize diagnostics page"]
  B --> C{"MQTT connected?"}

  C -- No --> D["Show disconnected status"]
  D --> E["Action: Reconnect"]
  E --> F["MQTT connection attempt"]
    F --> C

  C -- Yes --> G["Show MQTT controls"]
  G --> H{"Action type"}

  H -- Publish message --> I["Enter topic + payload"]
  I --> J["Send publish"]
  J --> K{"Send successful?"}
  K -- No --> L["Error toast / keep input"]
    L --> I
  K -- Yes --> M["Success toast"]

  H -- Read activity --> N["Show message history"]
  N --> O{"New messages?"}
  O -- Yes --> P["Refresh live list"]
    P --> N
  O -- No --> N

  H -- Quick commands --> Q["Send predefined command"]
    Q --> K

  M --> R["State and history consistent"]
    N --> R

     A:::start
     B:::action
     C:::decision
     D:::warning
     E:::action
     F:::action
     G:::action
     H:::decision
     I:::action
     J:::action
     K:::decision
     L:::warning
     M:::result
     N:::action
     O:::decision
     P:::action
     Q:::action
     R:::result
    classDef start fill:#0ea5e9,stroke:#0369a1,color:#ffffff,stroke-width:2px
    classDef action fill:#e2e8f0,stroke:#64748b,color:#0f172a,stroke-width:1.5px
    classDef decision fill:#fef3c7,stroke:#d97706,color:#78350f,stroke-width:2px
    classDef result fill:#dcfce7,stroke:#16a34a,color:#14532d,stroke-width:2px
    classDef warning fill:#fee2e2,stroke:#dc2626,color:#7f1d1d,stroke-width:1.8px
```

---