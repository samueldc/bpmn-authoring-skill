# BPMN Validation Errors

Common `bpmn-moddle` parse errors, their root causes, and how to fix them.

---

## Parse-time errors (bpmn-moddle rejects the file)

### ERR-001: `missing attribute 'id'`
**Cause:** An element is missing its `id` attribute.  
**Fix:** Add a unique `id` to every element — events, tasks, gateways, flows, and definitions.

### ERR-002: `unknown element <xyz>`
**Cause:** An element type not in the BPMN 2.0 schema or a typo.  
**Fix:** Check spelling. Common typos: `<exclusiveGateway>` (not `<exclusivegateway>`), `<sequenceFlow>` (not `<SequenceFlow>`). BPMN is case-sensitive.

### ERR-003: `unresolved reference 'xyz'`
**Cause:** A `sourceRef`, `targetRef`, `attachedToRef`, `messageRef`, or `signalRef` points to an ID that does not exist.  
**Fix:** Verify every reference resolves to a declared element ID. Message and Signal elements must be declared as siblings of `<process>` inside `<definitions>`, not inside `<process>`.

### ERR-004: `targetNamespace is required`
**Cause:** Missing `targetNamespace` attribute on `<definitions>`.  
**Fix:** Add any valid URI, e.g. `targetNamespace="http://bpmn.io/schema/bpmn"`. The value is not read by the engine — it is required by the BPMN 2.0 XML schema only. When editing an existing file, preserve the namespace already declared — changing it is unnecessary and may break external references in BPMN collaboration diagrams.

### ERR-005: XML is not well-formed
**Cause:** Unclosed tags, wrong nesting, or illegal characters.  
**Fix:**
- Every opened tag must be closed: `<task ...>...</task>` or `<task .../>`.
- `<incoming>` and `<outgoing>` are child elements of activities/events, not attributes.
- In expressions inside XML content, escape `&` as `&amp;`, `<` as `&lt;`, `>` as `&gt;`.
- In attribute values, escape `"` as `&quot;`.

---

## Engine-time errors

### ERR-010: `process has no startEvent`
**Cause:** No `<startEvent>` exists in the process.  
**Fix:** Add exactly one `<startEvent>` per process (sub-processes have their own).

### ERR-011: `token stuck — no outgoing flow`
**Cause:** A token reached an element with no matching outgoing flow (all conditions false on exclusiveGateway with no default).  
**Fix:** Add a `default` attribute to the gateway pointing to a fallback flow. Ensure at least one condition will always be true.

### ERR-012: `parallelGateway join never fires`
**Cause:** A parallel join gateway is waiting for tokens that will never arrive (e.g., one branch leads to an endEvent before reaching the join).  
**Fix:** In a parallel split, ALL branches must converge at the join gateway. If one branch can end early, use a different pattern: an `eventBasedGateway` or `inclusiveGateway`.

### ERR-013: `condition expression evaluation error`
**Cause:** Expression references a variable that doesn't exist, or has a syntax error.  
**Fix:**
- Wrap expressions in `{{...}}`.
- Only reference `variables`, `instance`, and `now()` — no global JS objects.
- Check for typos in variable names.
- String comparisons need quotes: `{{variables.status == 'approved'}}`, not `{{variables.status == approved}}`.

### ERR-014: `timerEvent expression not ISO 8601`
**Cause:** Timer value is not a valid ISO 8601 string.  
**Fix:**
- Duration: `PT1H` (1 hour), `P1D` (1 day), `P2DT3H` (2 days 3 hours).
- Date: `2026-12-31T09:00:00Z` (must include time zone).
- Cycle: `R3/PT1H` (repeat 3 times, every hour) or `0 9 * * 1-5` (cron).
- Do NOT use `{{expression}}` inside timer values.

### ERR-015: `boundaryEvent has no attachedToRef`
**Cause:** A `<boundaryEvent>` is missing the `attachedToRef` attribute.  
**Fix:** Set `attachedToRef` to the `id` of the task or sub-process the boundary event is attached to.

---

## Data / IO warnings (non-fatal but incorrect behavior)

### WARN-001: `userTask has no ioSpecification — no variables exposed to the task UI`
**Cause:** A `<userTask>` has no `<ioSpecification>` element.  
**Behavior:** The engine exposes **no variables** to the task UI for this task. This is the secure default.  
**Fix if needed:** Add `<ioSpecification>` with `<dataInput>` and `<dataOutput>` elements for each variable the form needs.

### WARN-002: `dataInput name does not match any process variable`
**Cause:** A `<dataInput name="xyz">` references a variable name that is never set in the process.  
**Behavior:** The frontend receives `undefined` for that field.  
**Fix:** Ensure the variable name in `dataInput` matches exactly (case-sensitive) the variable name set by a previous task's `dataOutput` or an initial variable passed at instantiation.

---

## XML escaping quick reference

| Character | Use inside XML element content | Use inside XML attribute value |
|---|---|---|
| `&` | `&amp;` | `&amp;` |
| `<` | `&lt;` | `&lt;` |
| `>` | `&gt;` (optional) | `&gt;` (optional) |
| `"` | `"` | `&quot;` |
| `'` | `'` | `&apos;` (if delimited by `'`) |

**Expression example with escaping:**
```xml
<!-- Inside element content — OK -->
<conditionExpression xsi:type="tFormalExpression">
  {{variables.score &gt;= 700 &amp;&amp; variables.debt &lt; 5000}}
</conditionExpression>
```

---

## ID naming conventions

| Category | Convention | Example |
|---|---|---|
| Process | kebab-case | `order-approval` |
| Events | `start`, `end`, `end_{reason}`, `catch_{name}` | `end_rejected`, `catch_timeout` |
| Tasks | `verb_noun` (snake_case) | `review_request`, `send_email` |
| Gateways | `gw_{purpose}` | `gw_decision`, `gw_split` |
| Flows | `flow_{source}_to_{target}` | `flow_review_to_gw` |
| Sub-process internals | prefix with `sub_` | `sub_start`, `sub_flow_1` |
| Boundary events | `{type}_boundary_{task}` | `timeout_boundary_review` |
| Messages / Signals | `msg_{name}`, `sig_{name}` | `msg_payment_confirmed` |
| Errors | `err_{name}` | `err_timeout` |
