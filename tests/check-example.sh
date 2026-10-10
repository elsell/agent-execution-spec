#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp "$root"/examples/uppercase/{discover.sh,run.sh,message.txt} "$work/"
cd "$work"

item=$(bash discover.sh)
printf '%s\n' "$item" | jq -e '.id == "message" and .data.source == "message.txt"' > /dev/null
cmp message.txt "$root/examples/uppercase/message.txt"
[[ ! -e generated ]]
[[ $(find . -type f | wc -l) -eq 3 ]]

printf '%s\n' "$item" | bash run.sh 2> event.log
printf 'HELLO, AGENTS!\n' | cmp - generated/MESSAGE.txt
sed 's/^@agent //' event.log | jq -e '.event == "document.uppercased"' > /dev/null
before=$(stat -c '%i:%y' generated/MESSAGE.txt)
printf '%s\n' "$item" | bash run.sh 2> retry.log
[[ ! -s retry.log ]]
[[ "$before" == "$(stat -c '%i:%y' generated/MESSAGE.txt)" ]]
[[ -z $(bash discover.sh) ]]

printf 'New work\n' > message.txt
[[ $(bash discover.sh) == "$item" ]]
printf '%s\n' "$item" | bash run.sh 2> event.log
printf 'NEW WORK\n' | cmp - generated/MESSAGE.txt
[[ -z $(bash discover.sh) ]]

# JSON characters are ordinary file contents, never shell code.
printf 'a "quote" and a \\ slash\nsecond line\n' > message.txt
printf '%s\n' "$item" | bash run.sh 2> event.log
LC_ALL=C tr '[:lower:]' '[:upper:]' < message.txt | cmp - generated/MESSAGE.txt
[[ -z $(bash discover.sh) ]]
rm message.txt
printf '%s\n' "$item" | bash run.sh
[[ -z $(bash discover.sh) ]]
if printf 'invalid JSON' | bash run.sh 2>/dev/null; then
  echo 'Invalid JSON unexpectedly succeeded' >&2
  exit 1
fi
if printf '{"data":{"source":"other.txt"}}' | bash run.sh; then
  echo 'Unexpected source unexpectedly succeeded' >&2
  exit 1
fi
printf '%s\n' 'Passed: read-only discovery, completion, retries, changed input, text characters, missing input, invalid input.'
