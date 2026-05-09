# bpmn-xml-generator

A [Claude Code](https://claude.ai/code) skill that generates valid BPMN 2.0 XML files from plain-language descriptions. Describe a business process in natural language and get production-ready XML compatible with any `bpmn-moddle`-based process engine (Camunda, Flowable, and compatible engines).

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

---

## What it does

When installed, this skill activates automatically whenever you ask Claude Code to create, model, design, or fix a BPMN process. It:

- **Gathers information before writing** — asks for missing details (assignees, conditions, variable names) in a single focused question rather than generating incomplete XML.
- **Produces schema-valid XML** — output is parseable by `bpmn-moddle` without errors.
- **Enforces structural correctness** — validates sequence flow connectivity, gateway conditions, timer formats (ISO 8601), and Camunda extension attribute usage before outputting.
- **Includes copy-paste patterns** — for all common element types: `userTask`, `serviceTask`, `exclusiveGateway`, `parallelGateway`, timer events, boundary events, message correlation, DMN rule tasks, sub-processes, and `callActivity`.

---

## Requirements

- [Claude Code](https://claude.ai/code) (CLI, IDE extension, or web)
- A Claude subscription that supports skills

---

## Installation

Run from the **root of your project**:

```sh
curl -fsSL https://raw.githubusercontent.com/samueldc/bpmn-xml-generator/main/install.sh | sh
```

The skill is installed into `.claude/skills/bpmn-xml-generator/` inside your project. Restart Claude Code (or start a new session) to activate it.

### Global installation

To make the skill available in **all your projects**:

```sh
curl -fsSL https://raw.githubusercontent.com/samueldc/bpmn-xml-generator/main/install.sh | GLOBAL=1 sh
```

This installs to `~/.claude/skills/bpmn-xml-generator/`.

### Manual installation

Clone the repository and copy the skill directory into your project:

```sh
git clone https://github.com/samueldc/bpmn-xml-generator.git
cp -r bpmn-xml-generator/.claude/skills/bpmn-xml-generator .claude/skills/
```

---

## Use cases

### Model a process from scratch

```
Create a BPMN for an expense reimbursement process. A finance analyst reviews
requests over $500, while smaller amounts are auto-approved.
```

The skill will ask for any missing details (assignee, variable names, condition expressions) before generating the XML.

### Convert a description or diagram to BPMN

```
Convert this flow to BPMN:
1. Customer places an order
2. System reserves stock
3. Wait up to 24h for payment confirmation
4. If payment received → ship order; if timeout → cancel order and release stock
```

### Fix or edit an existing BPMN file

```
Add a 48-hour boundary timer to the "KYC Review" task that escalates to a
senior analyst if not completed in time.
```

### Common patterns covered

| Pattern | Elements used |
|---|---|
| Human approval flow | `userTask`, `exclusiveGateway` |
| Parallel steps (AND split/join) | `parallelGateway` |
| Wait for external event | `intermediateCatchEvent` (Message or Timer) |
| Timeout escalation | `boundaryEvent` (Timer, interrupting) |
| Race between events | `eventBasedGateway` |
| DMN decision table | `businessRuleTask` with `camunda:decisionRef` |
| Call a sub-process | `callActivity` |
| Script / computed variable | `scriptTask` |

---

## How the skill works

The skill is defined in `.claude/skills/bpmn-xml-generator/SKILL.md` and loads additional reference files on demand:

| File | Purpose |
|---|---|
| `SKILL.md` | Entry point: authoring rules, element list, patterns, validation checklist |
| `references/elements.md` | Full attribute reference for every supported element |
| `references/examples.md` | 4 complete, ready-to-upload BPMN examples |
| `references/validation-errors.md` | Common `bpmn-moddle` parse errors and fixes |

---

## Contributing

Issues and pull requests are welcome.

### Reporting a bug or requesting a feature

1. Check [existing issues](https://github.com/samueldc/bpmn-xml-generator/issues) to avoid duplicates.
2. Open a [new issue](https://github.com/samueldc/bpmn-xml-generator/issues/new) with:
   - A clear title describing the problem or request.
   - For bugs: the prompt you used, the XML output, and the error (parse or engine error message).
   - For feature requests: the BPMN pattern or element you need and a concrete example.

### Submitting a pull request

1. Fork the repository and create a branch from `main`.
2. Make your changes to the skill files under `.claude/skills/bpmn-xml-generator/`.
3. Verify that any new XML snippets are valid BPMN 2.0 (parseable by `bpmn-moddle`).
4. Open a pull request with a description of what changed and why.

Contributions that add new element patterns, fix incorrect documentation, or improve the information-gathering prompts are especially welcome.

---

## License

[Apache License 2.0](LICENSE)
