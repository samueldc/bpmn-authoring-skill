# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is a **Claude Code skill** for generating valid BPMN 2.0 XML files compatible with BPMN 2.0-compliant process engines. It has no build system, test runner, or application code — it is entirely documentation and skill configuration.

The skill is registered at `.claude/skills/bpmn-xml-generator/` and is invoked automatically when users ask to create, model, or convert a business process or BPMN diagram.

## File structure

```
.claude/skills/bpmn-xml-generator/
  SKILL.md                        # Entry point: skill frontmatter + all authoring rules
  references/
    elements.md                   # Full attribute reference for every supported element
    examples.md                   # 4 complete valid BPMN examples (ready-to-upload)
    validation-errors.md          # bpmn-moddle parse errors and fixes
```

## Architecture and design constraints

### Engine-compatibility constraints
- Parser: **`bpmn-moddle`** (bpmn-io library) against OMG BPMN 2.0 schema
- Expression syntax: `{{variables.fieldName}}` — never FEEL (`#{}`) or UEL (`${}`)
- Timer values: ISO 8601 only — `{{...}}` is not valid inside timer expressions
- Camunda namespace (`xmlns:camunda="http://camunda.org/schema/1.0/bpmn"`) required for `userTask` attributes (`assignee`, `candidateGroups`, `dueDate`, `formKey`) and `callActivity`/`businessRuleTask` variable passing
- `<process isExecutable="true">` is mandatory
- `targetNamespace` on `<definitions>` is mandatory (any valid URI; value is not read by the engine — `http://bpmn.io/schema/bpmn` is the conventional default for new files)
- `<message>` and `<signal>` elements must be declared as siblings of `<process>` inside `<definitions>`, not inside `<process>`
- NOT supported: CMMN, Choreography, Conversation, DataStore

### Output conventions
- Process IDs: kebab-case (becomes the process identifier/key in the engine)
- Flow IDs: `flow_{source}_to_{target}`
- Gateway IDs: `gw_{purpose}`
- All `<sequenceFlow>` elements grouped at the bottom of `<process>` after all nodes
- 2-space indentation throughout


### Information gathering (skill behavior)
The skill must ask before writing whenever the process description is incomplete. Required: process key, name, happy-path steps, human tasks with assignees, service tasks with implementation type, and any gateway conditions. All missing items are asked in a single response.

## Editing guidelines

- `SKILL.md` is the authoritative source of truth for skill behavior. All rules, patterns, and constraints live there.
- `elements.md` is reference-only — update it when supported engine extensions change.
- `examples.md` examples must remain valid BPMN that can be uploaded via `POST /v1/definitions`. Do not add examples that would fail `bpmn-moddle` parsing.
- `validation-errors.md` — add new entries when new error patterns are discovered; keep error codes sequential.
- XML escaping in examples: `&&` → `&amp;&amp;`, `<` → `&lt;` inside element content and attribute values.
