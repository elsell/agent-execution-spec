"""Exercise the real scripts in isolated directories; no platform is simulated."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as directory:
    work = Path(directory)
    for name in ("discover.sh", "run.sh", "message.txt"):
        shutil.copy(root / "examples/uppercase" / name, work / name)

    def invoke(script, item=None):
        return subprocess.run(["bash", script], cwd=work, input=item,
                              text=True, capture_output=True)

    before = {p.name: p.read_bytes() for p in work.iterdir()}
    discovery = invoke("discover.sh")
    assert discovery.returncode == 0 and len(discovery.stdout.splitlines()) == 1
    assert before == {p.name: p.read_bytes() for p in work.iterdir()}, "Discovery mutated state"
    item = json.loads(discovery.stdout)
    assert set(item) == {"id", "data"}
    first = invoke("run.sh", discovery.stdout)
    assert first.returncode == 0, first.stderr
    assert json.loads(first.stderr.removeprefix("@agent "))["event"] == "document.uppercased"
    output = work / "generated/MESSAGE.txt"
    assert output.read_text() == "HELLO, AGENTS!\n"
    stat = output.stat()
    retry = invoke("run.sh", discovery.stdout)
    assert retry.returncode == 0 and retry.stderr == ""
    assert output.stat().st_mtime_ns == stat.st_mtime_ns, "Retry rewrote the output"
    assert invoke("discover.sh").stdout == ""
    (work / "message.txt").write_text("New work\n")
    new = invoke("discover.sh")
    assert json.loads(new.stdout)["id"] != item["id"]
    assert invoke("run.sh", discovery.stdout).returncode == 0
    assert output.read_text() == "HELLO, AGENTS!\n", "Stale work changed the output"
    assert invoke("run.sh", new.stdout).returncode == 0
    assert output.read_text() == "NEW WORK\n"
    assert invoke("discover.sh").stdout == ""
    (work / "message.txt").unlink()
    assert invoke("run.sh", new.stdout).returncode == 0
    assert invoke("discover.sh").stdout == ""
    assert invoke("run.sh", "invalid JSON").returncode != 0
print("Example checks passed: read-only discovery, completion, retry, new work, stale work, missing source, invalid input")
