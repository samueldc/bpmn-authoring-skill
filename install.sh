#!/bin/sh
# install.sh — installs the bpmn-xml-generator skill into the current project.
#
# Compatible with Claude Code and Cline. The default path (.claude/skills/) is
# recognised by both tools. Use TARGET=cline to install to .cline/skills/ instead.
#
# Usage (run from your project root):
#
#   Claude Code or Cline (shared path):
#     curl -fsSL https://raw.githubusercontent.com/samueldc/bpmn-xml-generator/main/install.sh | sh
#
#   Cline native path:
#     curl -fsSL https://raw.githubusercontent.com/samueldc/bpmn-xml-generator/main/install.sh | TARGET=cline sh
#
#   Global — Claude Code or Cline (shared path):
#     curl -fsSL https://raw.githubusercontent.com/samueldc/bpmn-xml-generator/main/install.sh | GLOBAL=1 sh
#
#   Global — Cline native path:
#     curl -fsSL https://raw.githubusercontent.com/samueldc/bpmn-xml-generator/main/install.sh | GLOBAL=1 TARGET=cline sh

set -e

REPO="samueldc/bpmn-xml-generator"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/.claude/skills/bpmn-xml-generator"
SKILL="bpmn-xml-generator"

# Resolve destination directory
if [ "${GLOBAL:-0}" = "1" ]; then
  if [ "${TARGET:-claude}" = "cline" ]; then
    DEST="${HOME}/.cline/skills/${SKILL}"
  else
    DEST="${HOME}/.claude/skills/${SKILL}"
  fi
else
  if [ "${TARGET:-claude}" = "cline" ]; then
    DEST=".cline/skills/${SKILL}"
  else
    DEST=".claude/skills/${SKILL}"
  fi
fi

# ---------------------------------------------------------------------------
# Detect download tool
# ---------------------------------------------------------------------------
if command -v curl > /dev/null 2>&1; then
  fetch() { curl -fsSL "$1" -o "$2"; }
elif command -v wget > /dev/null 2>&1; then
  fetch() { wget -q -O "$2" "$1"; }
else
  printf 'Error: curl or wget is required.\n' >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
printf 'Installing %s skill to %s\n' "$SKILL" "$DEST"

mkdir -p "$DEST/references"

fetch "$BASE_URL/SKILL.md"                        "$DEST/SKILL.md"
printf '  [ok] SKILL.md\n'

fetch "$BASE_URL/references/elements.md"          "$DEST/references/elements.md"
printf '  [ok] references/elements.md\n'

fetch "$BASE_URL/references/examples.md"          "$DEST/references/examples.md"
printf '  [ok] references/examples.md\n'

fetch "$BASE_URL/references/validation-errors.md" "$DEST/references/validation-errors.md"
printf '  [ok] references/validation-errors.md\n'

printf '\nDone. Restart Claude Code or Cline (or start a new session) to activate the skill.\n'
