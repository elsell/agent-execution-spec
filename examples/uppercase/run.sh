#!/usr/bin/env bash
set -euo pipefail

source=$(jq -er '.data.source')
[[ "$source" == "message.txt" ]] || exit 1
[[ -f "$source" ]] || exit 0

# A retry is successful without changing an already-correct result.
if cmp -s <(LC_ALL=C tr '[:lower:]' '[:upper:]' < "$source") generated/MESSAGE.txt; then
  exit 0
fi

mkdir -p generated
temporary=$(mktemp generated/.MESSAGE.XXXXXX)
trap 'rm -f "$temporary"' EXIT
LC_ALL=C tr '[:lower:]' '[:upper:]' < "$source" > "$temporary"
mv "$temporary" generated/MESSAGE.txt

printf '%s\n' '@agent {"event":"document.uppercased"}' >&2
