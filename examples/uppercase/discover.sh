#!/usr/bin/env bash
set -euo pipefail

[[ -f message.txt ]] || exit 0

# Nothing to do when the output already matches.
if cmp -s <(LC_ALL=C tr '[:lower:]' '[:upper:]' < message.txt) generated/MESSAGE.txt; then
  exit 0
fi

jq -nc '{id: "message", data: {source: "message.txt"}}'
