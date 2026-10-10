#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import hashlib
import json
from pathlib import Path

source = Path("message.txt")
result = Path("generated/MESSAGE.txt")
if not source.exists():
    raise SystemExit(0)
text = source.read_text(encoding="utf-8")
if result.exists() and result.read_text(encoding="utf-8") == text.upper():
    raise SystemExit(0)
print(json.dumps({
    "id": hashlib.sha256(text.encode("utf-8")).hexdigest(),
    "data": {"text": text},
}))
PY
