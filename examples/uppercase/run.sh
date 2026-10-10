#!/usr/bin/env bash
set -euo pipefail
python3 -c '
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile

item = json.load(sys.stdin)
text = item["data"]["text"]
if item["id"] != hashlib.sha256(text.encode("utf-8")).hexdigest():
    raise ValueError("Work ID does not match its text")
source = Path("message.txt")
if not source.exists() or source.read_text(encoding="utf-8") != text:
    raise SystemExit(0)  # This snapshot no longer needs work.
result = Path("generated/MESSAGE.txt")
desired = text.upper()
if result.exists() and result.read_text(encoding="utf-8") == desired:
    raise SystemExit(0)  # Already handled: a retry has no further effect.
result.parent.mkdir(exist_ok=True)
temporary = None
try:
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8",
                                     dir=result.parent, delete=False) as output:
        temporary = output.name
        output.write(desired)
    os.replace(temporary, result)
finally:
    if temporary is not None and os.path.exists(temporary):
        os.unlink(temporary)
print("@agent " + json.dumps({
    "event": "document.uppercased",
    "data": {"path": str(result)},
}), file=sys.stderr)
'
