#!/usr/bin/env python3
"""Prove benchmark sensitivity and failure handling with a prepared Zi checkout."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--zi", type=Path, required=True)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
runner = repo / "benchmarks/run.py"
with tempfile.TemporaryDirectory(prefix="meta-benchmark-check-") as directory:
    root = Path(directory)
    spec = {"zi": str(args.zi.resolve()), "annex": str(repo), "cases": {"loader": {}}}
    baseline = root / "baseline.json"
    baseline.write_text(json.dumps(spec))
    output = root / "control.json"
    command = [sys.executable, str(runner), str(baseline), "--baseline", str(baseline), "--samples", "3", "--warmups", "1", "--output", str(output)]
    subprocess.run(command, check=True)
    report = json.loads(output.read_text())
    assert len(report["cases"]["loader"]["results"]["candidate"]["repeat_ms"]["samples"]) == 3
    changed = root / "annex"
    changed.mkdir()
    shutil.copy2(repo / "z-a-meta-plugins.plugin.zsh", changed)
    shutil.copytree(repo / "functions", changed / "functions")
    handler = changed / "functions/_z_a_meta_plugins_before_load_handler"
    original = handler.read_text()
    handler.write_text("command sleep 0.01\n" + original)
    spec["annex"] = str(changed)
    candidate = root / "candidate.json"
    candidate.write_text(json.dumps(spec))
    command[2] = str(candidate)
    command[-1] = str(root / "slow.json")
    subprocess.run(command, check=True)
    report = json.loads((root / "slow.json").read_text())
    assert report["cases"]["loader"]["change"]["repeat_ms"]["median_delta_ms"] > 5
    mismatch = subprocess.run(command + ["--mode", "upstream"], capture_output=True, text=True)
    assert mismatch.returncode != 0 and "changes inputs" in mismatch.stderr
    assert json.loads((root / "slow.json").read_text())["status"] == "incomplete"
    handler.write_text("return 1\n")
    command[-1] = str(root / "failure.json")
    result = subprocess.run(command, capture_output=True, text=True)
    assert result.returncode != 0
    failure = json.loads((root / "failure.json").read_text())
    assert failure["failure"]["variant"] == "candidate"
    assert "loader" not in failure["cases"]
print("ok - A/A samples, deliberate slowdown and functional-failure rejection")
