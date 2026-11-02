#!/usr/bin/env bash
# Allows a prompt only when the selected model matches a line in allowed-models.txt,
# which lives next to this script.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  printf 'allow-models.sh requires jq on PATH\n' >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
list_file="${script_dir}/allowed-models.txt"
list_label=".cursor/hooks/allowed-models.txt"

deny() {
  local message="$1"
  message="${message//\\/\\\\}"
  message="${message//\"/\\\"}"
  printf '{"continue":false,"user_message":"%s"}\n' "$message"
}

allow() {
  printf '{"continue":true}\n'
}

if [[ ! -f "$list_file" ]]; then
  deny "The allow list is missing: ${list_label}"
  exit 0
fi

allowed=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  if [[ -z "$line" || "$line" == \#* ]]; then
    continue
  fi
  allowed+=("$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')")
done < "$list_file"

if [[ ${#allowed[@]} -eq 0 ]]; then
  deny "The allow list in ${list_label} is empty. Add a model name, one per line."
  exit 0
fi

payload="$(cat)"
if [[ -z "${payload//[[:space:]]/}" ]]; then
  payload="{}"
fi

model="$(jq -r '.model // ""' <<<"$payload" | tr '[:upper:]' '[:lower:]')"
if [[ -z "$model" ]]; then
  deny "This prompt did not include a model name, so it was refused."
  exit 0
fi

for piece in "${allowed[@]}"; do
  if [[ "$model" == *"$piece"* ]]; then
    allow
    exit 0
  fi
done

deny "${model} is not on the allow list in ${list_label}"
