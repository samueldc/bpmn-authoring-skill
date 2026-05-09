---
name: bpmn-authoring
description: >
  Generate well-formed, valid BPMN 2.0 XML files compatible with BPMN 2.0-compliant process engines.
  Use this skill whenever the user asks to create, write, design, model, or define a business process,
  workflow, or BPMN diagram — even if they just describe a flow in plain language ("I need a process
  that does X then Y..."). Also use it when asked to convert YAML/JSON process definitions to BPMN,
  or to edit/fix an existing BPMN file. The skill guides information gathering when the request is
  incomplete, produces schema-valid XML, and enforces schema and compatibility constraints.
---

# BPMN Authoring

Produces valid BPMN 2.0 XML parseable by `bpmn-moddle` and executable by BPMN 2.0-compliant process engines.

---

## 0. Orientation: what you are building

This skill targets engines that parse BPMN via **`bpmn-moddle`** (the bpmn-io library), such as Camunda and Flowable-compatible engines.  
Key facts that govern every file you generate:

| Fact | Detail |
|---|---|
| Root namespace | `xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"` |
| Root element | `<definitions>` with mandatory `id` and `targetNamespace` (any valid URI; not read by the engine — it is required by the BPMN 2.0 XML schema only) |
| Each process | `<process id="..." isExecutable="true">` |
| Conditions on flows | `<conditionExpression>{{expression}}</conditionExpression>` (engine-specific; verify with your engine — FEEL is the BPMN-standard alternative) |
| Assignees / dynamic values | `{{variables.fieldName}}` inside string attributes |
| DMN integration | `<businessRuleTask camunda:decisionRef="decision-id">` — `decisionRef` must match the `id` of a DMN definition already registered in the engine |
| IDs | All elements **must** have a unique `id` attribute. Convention: `snake_case` or `PascalCase_N` |
| `isExecutable` | Always `true` for processes intended for execution |

---

## 1. Information gathering — ask before writing

**Never generate a BPMN file from an incomplete description.** If the user's prompt is missing any of the items below, ask them before proceeding. Ask all missing items in a single response (not one at a time).

### 1.1 Always required

- [ ] **Process key** — the logical identifier (e.g., `order-approval`). Must be URL-safe, lowercase, hyphen-separated.
- [ ] **Process name** — human-readable label.
- [ ] **Happy-path steps** — the sequence of activities from start to end (at least one activity).
- [ ] **Human tasks** — which steps require human action? Who is the assignee or candidateGroup?
- [ ] **Service tasks** — which steps call external systems? What is the `implementation` type? (`webhook` or `http`)
- [ ] **Gateways** — are there any conditional branches? What are the conditions?

### 1.2 Ask when relevant

- [ ] **Timer events** — any steps that wait for a time or duration? (ISO 8601: `PT1H`, `2026-12-01T09:00:00Z`, `R3/PT24H`)
- [ ] **Message / Signal events** — any steps that wait for or emit an external message?
- [ ] **Error / boundary events** — any error handling on tasks?
- [ ] **Sub-processes** — any embedded sub-flows?
- [ ] **DMN decisions** — does any step evaluate a decision table? If so, what is the `id` of the DMN definition that must already exist in the engine? (That `id` goes in `camunda:decisionRef`.)
- [ ] **Variable names** — what process variables are used? (needed for expressions and `dataInputAssociation`)
- [ ] **Data visibility** — for each `userTask`, which variables should the frontend see? (maps to `dataInput`/`dataOutput` in `ioSpecification`)
- [ ] **Process-level variables** — are there default/initial variable values?

### 1.3 Clarify ambiguity

If the user describes a flow like "approve or reject", confirm:
- Is this an `exclusiveGateway` (XOR — one path only)?
- Are both outcomes leading to different end states?
- What is the condition expression for each outgoing flow?

---

## 2. Supported BPMN elements

Read `references/elements.md` for the full attribute list of each element.  
Below is the complete list of supported types — do not use any element not on this list.

### Events
| XML element | Type | Notes |
|---|---|---|
| `<startEvent>` | `startEvent` | None, Timer, Message, Signal, Conditional |
| `<endEvent>` | `endEvent` | None, Terminate, Message, Signal, Error, Escalation |
| `<intermediateCatchEvent>` | `intermediateCatchEvent` | Timer, Message, Signal, Conditional |
| `<intermediateThrowEvent>` | `intermediateThrowEvent` | Message, Signal, Escalation |
| `<boundaryEvent>` | `boundaryEvent` | Timer (interrupting/non), Error, Message, Signal, Escalation |

### Activities
| XML element | Type | Notes |
|---|---|---|
| `<task>` | generic task | passes through immediately |
| `<userTask>` | `userTask` | `assignee`, `candidateGroups`, `formKey`, `dueDate` |
| `<serviceTask>` | `serviceTask` | `implementation="webhook"` or `"http"` |
| `<scriptTask>` | `scriptTask` | expression evaluated against `variables` |
| `<sendTask>` | `sendTask` | dispatches message/webhook |
| `<receiveTask>` | `receiveTask` | waits for correlated message |
| `<businessRuleTask>` | `businessRuleTask` | `camunda:decisionRef` must contain the `id` of a previously registered DMN definition |
| `<callActivity>` | `callActivity` | calls another process definition |
| `<subProcess>` | `subProcess` | embedded sub-flow |

### Gateways
| XML element | Behavior |
|---|---|
| `<exclusiveGateway>` | XOR — exactly one outgoing flow taken |
| `<parallelGateway>` | AND — all flows activated (join requires all tokens) |
| `<inclusiveGateway>` | OR — one or more flows based on conditions |
| `<eventBasedGateway>` | race — first event wins |

### Connectors
| XML element | Notes |
|---|---|
| `<sequenceFlow>` | `sourceRef`, `targetRef`, optional `<conditionExpression>` |

### Not commonly supported by BPMN process engines
CMMN, Choreography, Conversation, DataStore, Association (rendered only).

---

## 3. XML structure template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<definitions
  xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xsi:schemaLocation="http://www.omg.org/spec/BPMN/20100524/MODEL
                      http://www.omg.org/spec/BPMN/2.0/20100501/BPMN20.xsd"
  id="Definitions_{process-key}"
  targetNamespace="http://bpmn.io/schema/bpmn" <!-- any valid URI; this value is not used by the engine -->
  exporter="bpmn-authoring"
  exporterVersion="1.0">

  <process id="{process-key}" name="{Process Name}" isExecutable="true">

    <!-- ═══ START ═══ -->
    <startEvent id="start" name="Start">
      <outgoing>flow_start_to_first</outgoing>
    </startEvent>

    <!-- ═══ ACTIVITIES ═══ -->
    <!-- ... -->

    <!-- ═══ GATEWAYS ═══ -->
    <!-- ... -->

    <!-- ═══ END ═══ -->
    <endEvent id="end" name="End"/>

    <!-- ═══ SEQUENCE FLOWS ═══ -->
    <!-- List ALL flows at the bottom for readability -->
    <sequenceFlow id="flow_start_to_first" sourceRef="start" targetRef="..."/>

  </process>

</definitions>
```

---

## 4. Element patterns — copy-paste ready

### userTask with assignee and data visibility
```xml
<userTask id="review_task" name="Review Request"
          camunda:assignee="{{variables.manager}}"
          camunda:candidateGroups="approvers">
  <extensionElements>
    <camunda:formData>
      <camunda:formField id="approved" label="Approved?" type="boolean"/>
      <camunda:formField id="comment"  label="Comment"   type="string"/>
    </camunda:formData>
  </extensionElements>
  <ioSpecification>
    <dataInput  id="in_amount"  name="amount"/>
    <dataInput  id="in_reason"  name="reason"/>
    <dataOutput id="out_approved" name="approved"/>
    <dataOutput id="out_comment"  name="comment"/>
  </ioSpecification>
  <incoming>flow_to_review</incoming>
  <outgoing>flow_from_review</outgoing>
</userTask>
```

### serviceTask (webhook)
```xml
<serviceTask id="notify_erp" name="Notify ERP"
             implementation="webService">
  <extensionElements>
    <camunda:connector>
      <camunda:connectorId>webhook</camunda:connectorId>
    </camunda:connector>
  </extensionElements>
  <incoming>flow_to_notify</incoming>
  <outgoing>flow_from_notify</outgoing>
</serviceTask>
```

### exclusiveGateway with conditions
```xml
<exclusiveGateway id="gw_approval" name="Approved?">
  <incoming>flow_to_gw</incoming>
  <outgoing>flow_approved</outgoing>
  <outgoing>flow_rejected</outgoing>
</exclusiveGateway>

<sequenceFlow id="flow_approved" sourceRef="gw_approval" targetRef="notify_approved">
  <conditionExpression xsi:type="tFormalExpression">{{variables.approved == true}}</conditionExpression>
</sequenceFlow>

<sequenceFlow id="flow_rejected" sourceRef="gw_approval" targetRef="end_rejected">
  <conditionExpression xsi:type="tFormalExpression">{{variables.approved == false}}</conditionExpression>
</sequenceFlow>
```

### timerEvent (intermediate catch — wait N hours)
```xml
<intermediateCatchEvent id="wait_24h" name="Wait 24h">
  <incoming>flow_to_timer</incoming>
  <outgoing>flow_from_timer</outgoing>
  <timerEventDefinition>
    <timeDuration xsi:type="tFormalExpression">PT24H</timeDuration>
  </timerEventDefinition>
</intermediateCatchEvent>
```

### boundaryEvent (timer, interrupting)
```xml
<boundaryEvent id="timeout_boundary" name="Timeout"
               attachedToRef="review_task"
               cancelActivity="true">
  <outgoing>flow_timeout</outgoing>
  <timerEventDefinition>
    <timeDuration xsi:type="tFormalExpression">PT48H</timeDuration>
  </timerEventDefinition>
</boundaryEvent>
```

### businessRuleTask (DMN decision)
```xml
<!-- 'credit-score-decision' must be the id of a DMN definition already registered in the engine -->
<businessRuleTask id="credit_check" name="Credit Score Check"
                  camunda:decisionRef="credit-score-decision">
  <extensionElements>
    <camunda:in  variables="all"/>
    <camunda:out variables="all"/>
  </extensionElements>
  <incoming>flow_to_credit</incoming>
  <outgoing>flow_from_credit</outgoing>
</businessRuleTask>
```

### messageStartEvent / messageCatchEvent
```xml
<!-- Start on external message -->
<startEvent id="start_on_message" name="Payment Received">
  <messageEventDefinition messageRef="msg_payment"/>
</startEvent>
<message id="msg_payment" name="payment_received"/>

<!-- Intermediate wait for message -->
<intermediateCatchEvent id="wait_payment" name="Wait for Payment">
  <incoming>flow_to_wait</incoming>
  <outgoing>flow_after_payment</outgoing>
  <messageEventDefinition messageRef="msg_payment"/>
</intermediateCatchEvent>
```

---

## 5. Expression syntax

This skill uses `{{expression}}` as the default condition syntax — **not** FEEL (`#{}`) and **not** UEL (`${}`). Expression syntax is engine-dependent; verify with your engine.

```
{{variables.amount > 1000}}                         → boolean condition
{{variables.status == 'approved'}}                  → string equality
{{variables.items.length > 0}}                      → array check
{{variables.manager || 'default@company.com'}}      → fallback
{{variables.score >= 700 && variables.debt < 5000}} → compound
```

Use in:
- `<conditionExpression>` on sequence flows
- `camunda:assignee` attribute on `userTask`
- Timer expressions **only use ISO 8601** (no `{{}}` in timer values)

---

## 6. Validation checklist

Before outputting the final XML, verify every item:

- [ ] Every element has a unique `id`
- [ ] Every `<sequenceFlow>` has `sourceRef` and `targetRef` pointing to existing element IDs
- [ ] Every element except end events has at least one `<outgoing>` child
- [ ] Every element except start events has at least one `<incoming>` child
- [ ] `<exclusiveGateway>` outgoing flows all have `<conditionExpression>` (except a default flow if `default` attribute is set)
- [ ] `<parallelGateway>` used for both split AND join — the join must have multiple `<incoming>` matching the split's `<outgoing>`
- [ ] `<boundaryEvent>` has `attachedToRef` pointing to a valid activity
- [ ] Timer expressions are valid ISO 8601: durations start with `P`, dates are full UTC timestamps
- [ ] `isExecutable="true"` on `<process>`
- [ ] `targetNamespace` is set on `<definitions>`
- [ ] No CMMN, Choreography, or DataStore elements (rarely supported by BPMN process engines)

---

## 7. Output format

1. Always output the complete XML (never truncate with `<!-- ... rest of process -->`)
2. Use consistent 2-space indentation
3. Group flows at the **end** of the process element, after all nodes
4. Add a brief inline comment above each logical section (START, ACTIVITIES, GATEWAYS, END, FLOWS)
5. If the file is longer than ~150 lines, offer to also write a summary table of elements and flows
6. After outputting the XML, remind the user to validate and upload it according to their engine's API.

---

## 8. Reference files

Read these when you need deeper detail — do not load them all at once:

| File | When to read |
|---|---|
| `references/elements.md` | Full attribute reference for each element type |
| `references/examples.md` | 4 complete end-to-end BPMN examples (approval, onboarding, timer escalation, message correlation) |
| `references/validation-errors.md` | Common bpmn-moddle parse errors and how to fix them |
