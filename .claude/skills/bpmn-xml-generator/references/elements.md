# BPMN Element Reference

Full attribute reference for commonly supported BPMN 2.0 elements.
Parsed by `bpmn-moddle` against the OMG BPMN 2.0 schema.

---

## Table of Contents
1. [Root Elements](#1-root-elements)
2. [Events](#2-events)
3. [Activities](#3-activities)
4. [Gateways](#4-gateways)
5. [Sequence Flows](#5-sequence-flows)
6. [Data & IO](#6-data--io)
7. [Event Definitions](#7-event-definitions)
8. [Extension Elements (Camunda-compatible)](#8-extension-elements-camunda-compatible)

---

## 1. Root Elements

### `<definitions>`
| Attribute | Required | Notes |
|---|---|---|
| `id` | ✅ | Unique identifier, e.g. `Definitions_order-approval` |
| `targetNamespace` | ✅ | Any valid URI. Not read by the engine — required by the BPMN 2.0 XML schema. Preserve the original value when editing existing files. For new files, `http://bpmn.io/schema/bpmn` is the conventional default. |
| `name` | — | Human label |
| `exporter` | — | Tool name |
| `exporterVersion` | — | Tool version |

Required namespaces on `<definitions>`:
```
xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
xmlns:camunda="http://camunda.org/schema/1.0/bpmn"
```

### `<process>`
| Attribute | Required | Notes |
|---|---|---|
| `id` | ✅ | Becomes the process identifier/key in the engine |
| `name` | ✅ | Human-readable label |
| `isExecutable` | ✅ | Must be `true` |
| `processType` | — | `None` (default), `Public`, `Private` |

---

## 2. Events

### `<startEvent>`
| Attribute | Notes |
|---|---|
| `id` | required |
| `name` | label shown in diagrams |

**None start** (no child event definition): process starts immediately on instantiation.  
**Timer start**: child `<timerEventDefinition>` — fires on schedule.  
**Message start**: child `<messageEventDefinition messageRef="...">` — fires when message arrives.  
**Signal start**: child `<signalEventDefinition signalRef="...">`.

### `<endEvent>`
| Attribute | Notes |
|---|---|
| `id` | required |
| `name` | label |

**None end**: normal completion.  
**Terminate end**: `<terminateEventDefinition/>` — cancels entire process instance.  
**Error end**: `<errorEventDefinition errorRef="..."/>` — triggers error boundary events.  
**Message end**: `<messageEventDefinition messageRef="..."/>` — sends message on completion.

### `<intermediateCatchEvent>`
| Attribute | Notes |
|---|---|
| `id` | required |
| `name` | label |

Supported definitions: Timer, Message, Signal, Conditional.  
Must have exactly one `<incoming>` and one `<outgoing>`.

### `<intermediateThrowEvent>`
Supported definitions: Message, Signal, Escalation.  
Common use cases include sending notifications to interested parties, triggering downstream messages, or signaling other processes. For example, a Message throw event can notify a user that an automated step completed before the next human task begins.

### `<boundaryEvent>`
| Attribute | Required | Notes |
|---|---|---|
| `id` | ✅ | |
| `name` | — | label |
| `attachedToRef` | ✅ | ID of the activity this event is attached to |
| `cancelActivity` | — | `true` (interrupting, default) or `false` (non-interrupting) |

Supported definitions: Timer, Error, Message, Signal, Escalation.  
Must have `<outgoing>` but **no** `<incoming>`.

---

## 3. Activities

### `<task>`
Generic task — passes through immediately with no side effects.
```xml
<task id="log_entry" name="Log Entry">
  <incoming>f1</incoming>
  <outgoing>f2</outgoing>
</task>
```

### `<userTask>`
| Attribute | Notes |
|---|---|
| `id` | required |
| `name` | displayed as task name in UI |
| `camunda:assignee` | specific user id or `{{variables.manager}}` |
| `camunda:candidateGroups` | comma-separated group names or `{{variables.team}}` |
| `camunda:dueDate` | ISO 8601 datetime or `{{variables.dueDate}}` |
| `camunda:formKey` | optional form key reference |

The `camunda:` prefix attributes require `xmlns:camunda="http://camunda.org/schema/1.0/bpmn"` on `<definitions>`.

For frontend data visibility, add `<ioSpecification>` with `<dataInput>` and `<dataOutput>` children. See section 6.

### `<serviceTask>`
| Attribute | Notes |
|---|---|
| `id` | required |
| `name` | label |
| `implementation` | `"webService"` for webhook/http dispatch |

The engine dispatches a webhook to the configured URL when this task is reached. The task completes automatically after dispatch (fire-and-forget) unless a correlating `receiveTask` follows.

### `<scriptTask>`
| Attribute | Notes |
|---|---|
| `id` | required |
| `name` | label |
| `scriptFormat` | `"javascript"` — a restricted subset; no `eval`, `require`, DOM, or network access |

```xml
<scriptTask id="compute_score" name="Compute Score" scriptFormat="javascript">
  <script>variables.score = variables.income / variables.debt * 10;</script>
  <incoming>f1</incoming>
  <outgoing>f2</outgoing>
</scriptTask>
```

⚠️ Scripts have no access to `eval`, `require`, DOM, or network. Only `variables`, `instance`, `now()`.

### `<sendTask>`
Dispatches a message or webhook and continues immediately.

### `<receiveTask>`
Waits for a correlated message before continuing.
```xml
<receiveTask id="wait_payment" name="Wait for Payment Confirmation"
             messageRef="msg_payment_confirmed">
  <incoming>f1</incoming>
  <outgoing>f2</outgoing>
</receiveTask>
```

### `<businessRuleTask>`
Evaluates a DMN decision table. The `camunda:decisionRef` attribute must contain the `id` of a DMN definition that has been previously registered in the engine. The referenced DMN definition must exist before the process instance reaches this task.
```xml
<businessRuleTask id="run_credit_rules" name="Credit Score Check"
                  camunda:decisionRef="my-decision-id">
  <extensionElements>
    <camunda:in  variables="all"/>
    <camunda:out variables="all"/>
  </extensionElements>
  <incoming>f1</incoming>
  <outgoing>f2</outgoing>
</businessRuleTask>
```

### `<callActivity>`
Invokes another process definition as a sub-process.
| Attribute | Notes |
|---|---|
| `calledElement` | key of the target process definition |

```xml
<callActivity id="run_kyc" name="Run KYC Process" calledElement="kyc-check">
  <extensionElements>
    <camunda:in  variables="all"/>
    <camunda:out variables="all"/>
  </extensionElements>
  <incoming>f1</incoming>
  <outgoing>f2</outgoing>
</callActivity>
```

### `<subProcess>`
Embedded sub-process. Contains its own start/end events and activities.
```xml
<subProcess id="sub_validation" name="Validation">
  <incoming>f1</incoming>
  <outgoing>f2</outgoing>
  <startEvent id="sub_start"><outgoing>sub_f1</outgoing></startEvent>
  <!-- ... sub-process elements ... -->
  <endEvent id="sub_end"/>
  <sequenceFlow id="sub_f1" sourceRef="sub_start" targetRef="..."/>
</subProcess>
```

---

## 4. Gateways

### `<exclusiveGateway>` (XOR)
Exactly one outgoing flow is taken based on conditions. The flow whose condition evaluates to `true` first (in document order) wins.

**Default flow**: set `default="flow_id"` on the gateway, and omit `<conditionExpression>` on that flow. It is taken when no other condition matches.

```xml
<exclusiveGateway id="gw_check" name="Check Result" default="flow_default">
  <incoming>f_in</incoming>
  <outgoing>flow_high</outgoing>
  <outgoing>flow_low</outgoing>
  <outgoing>flow_default</outgoing>
</exclusiveGateway>
```

### `<parallelGateway>` (AND)
**Split**: all outgoing flows are activated simultaneously.  
**Join**: waits for ALL incoming tokens before continuing. The same element ID is reused for both split and join — or separate elements can be used.

```xml
<!-- split -->
<parallelGateway id="gw_split">
  <incoming>f_in</incoming>
  <outgoing>f_branch_a</outgoing>
  <outgoing>f_branch_b</outgoing>
</parallelGateway>

<!-- join -->
<parallelGateway id="gw_join">
  <incoming>f_branch_a_done</incoming>
  <incoming>f_branch_b_done</incoming>
  <outgoing>f_after_join</outgoing>
</parallelGateway>
```

### `<inclusiveGateway>` (OR)
One or more outgoing flows taken. Every flow whose condition is `true` is activated. Same join semantics: waits for all activated tokens.

### `<eventBasedGateway>`
Race between events. The first event to arrive wins; others are cancelled.
```xml
<eventBasedGateway id="gw_race">
  <incoming>f_in</incoming>
  <outgoing>f_to_msg_catch</outgoing>
  <outgoing>f_to_timer_catch</outgoing>
</eventBasedGateway>
<!-- Must be followed by intermediateCatchEvents only -->
```

---

## 5. Sequence Flows

```xml
<sequenceFlow id="flow_id" name="optional label"
              sourceRef="source_element_id"
              targetRef="target_element_id">
  <!-- Optional condition (only on flows leaving exclusiveGateway or inclusiveGateway) -->
  <conditionExpression xsi:type="tFormalExpression">
    {{variables.approved == true}}
  </conditionExpression>
</sequenceFlow>
```

Rules:
- Every flow needs a unique `id`.
- `name` is optional but improves diagram readability.
- Conditions are only valid on flows leaving an `exclusiveGateway` or `inclusiveGateway`.
- A flow leaving a `parallelGateway` must NOT have a condition.

---

## 6. Data & IO

### `<ioSpecification>` on `userTask`
Controls which variables are exposed by the engine to external consumers (e.g. a task UI).
```xml
<ioSpecification>
  <dataInput  id="in_amount"       name="amount"/>
  <dataInput  id="in_justification" name="justification"/>
  <dataOutput id="out_approved"    name="approved"/>
  <dataOutput id="out_comment"     name="comment"/>
</ioSpecification>
```
- `dataInput` names must match process variable names exactly.
- `dataOutput` names define what variables the user sets when completing the task.
- If no `ioSpecification` is declared, the engine exposes **no variables** to the task UI (secure default).

### `<dataInputAssociation>` on `intermediateThrowEvent`
Controls which variables are included in the event payload when the throw event fires.
```xml
<intermediateThrowEvent id="notify_done" name="Analysis Complete">
  <dataInputAssociation>
    <sourceRef>creditScore</sourceRef>
    <sourceRef>approvedLimit</sourceRef>
  </dataInputAssociation>
  <messageEventDefinition messageRef="msg_analysis"/>
</intermediateThrowEvent>
```

---

## 7. Event Definitions

### `<timerEventDefinition>`
```xml
<!-- Duration (relative) -->
<timerEventDefinition>
  <timeDuration xsi:type="tFormalExpression">PT1H</timeDuration>
</timerEventDefinition>

<!-- Absolute date -->
<timerEventDefinition>
  <timeDate xsi:type="tFormalExpression">2026-12-31T09:00:00Z</timeDate>
</timerEventDefinition>

<!-- Repeating cycle -->
<timerEventDefinition>
  <timeCycle xsi:type="tFormalExpression">R3/PT24H</timeCycle>
</timerEventDefinition>
```

### `<messageEventDefinition>`
```xml
<messageEventDefinition messageRef="msg_payment"/>
<!-- Declare message at top level -->
<message id="msg_payment" name="payment_received"/>
```

### `<signalEventDefinition>`
```xml
<signalEventDefinition signalRef="sig_cancel"/>
<signal id="sig_cancel" name="cancel_order"/>
```

### `<errorEventDefinition>`
```xml
<errorEventDefinition errorRef="err_timeout"/>
<error id="err_timeout" name="TimeoutError" errorCode="TIMEOUT"/>
```

### `<terminateEventDefinition>`
```xml
<terminateEventDefinition/>
```

---

## 8. Extension Elements (Camunda-compatible)

These extensions use the Camunda namespace, supported by Camunda-compatible process engines.  
Add `xmlns:camunda="http://camunda.org/schema/1.0/bpmn"` to `<definitions>`.

| Extension | Element | Purpose |
|---|---|---|
| `camunda:assignee` | `userTask` | Fixed or dynamic assignee |
| `camunda:candidateGroups` | `userTask` | Comma-separated group names |
| `camunda:dueDate` | `userTask` | ISO datetime or expression |
| `camunda:formKey` | `userTask` | Form identifier |
| `camunda:in variables="all"` | `callActivity`, `businessRuleTask` | Pass all variables in |
| `camunda:out variables="all"` | `callActivity`, `businessRuleTask` | Receive all variables out |
| `camunda:connector/camunda:connectorId` | `serviceTask` | Connector type (`webhook`, `http`) |
| `camunda:decisionRef` | `businessRuleTask` | `id` of a previously registered DMN definition |

Example for `userTask` with all extension attributes:
```xml
<userTask id="approve_task" name="Approve"
          camunda:assignee="{{variables.manager}}"
          camunda:candidateGroups="finance,approvers"
          camunda:dueDate="{{variables.dueDate}}">
  <extensionElements>
    <camunda:formData>
      <camunda:formField id="approved" label="Approved?"   type="boolean"/>
      <camunda:formField id="reason"   label="Reason"      type="string"/>
      <camunda:formField id="amount"   label="Adj. Amount" type="long"/>
    </camunda:formData>
  </extensionElements>
  ...
</userTask>
```
