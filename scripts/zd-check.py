#!/usr/bin/env python3
"""Run repository checks and the prepared loader fixture inside zd."""
import argparse
import json
import os
import re
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--benchmark", action="store_true")
parser.add_argument("--samples", type=int, default=30)
parser.add_argument("--warmups", type=int, default=5)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
os.chdir(repo)
version = subprocess.check_output(["zsh", "-f", "-c", "print -r -- $ZSH_VERSION"], text=True).strip()
match = re.fullmatch(r"([0-9]+)\.([0-9]+)(?:\.([0-9]+))?", version)
if not match or tuple(int(value or 0) for value in match.groups()) < (5, 9, 2):
    parser.error("this repository requires Zsh 5.9.2 or newer")
output = Path(os.environ["ZD_OUTPUT_DIR"])
with (output / "tests.log").open("w") as log:
    for test in sorted(Path("tests").glob("*.zsh")):
        print("Checking", test, file=log, flush=True)
        subprocess.run(["zsh", "-f", str(test)], stdout=log, stderr=subprocess.STDOUT, check=True)
    for source in [Path("z-a-meta-plugins.plugin.zsh"), *sorted(Path("functions").glob("*"))]:
        subprocess.run(["zsh", "-f", "-n", str(source)], stdout=log, stderr=subprocess.STDOUT, check=True)
    subprocess.run(["python3", "tests/test_benchmark_report.py"], stdout=log, stderr=subprocess.STDOUT, check=True)
if args.benchmark:
    zi = Path(os.environ["ZD_INPUT_DIR"]) / "zi"
    if not (zi / "zi.zsh").is_file():
        parser.error("benchmark requires the prepared named Git input zi")
    with (output / "sensitivity.log").open("w") as log:
        subprocess.run(["python3", "tests/benchmark-check.py", "--zi", str(zi)],
                       stdout=log, stderr=subprocess.STDOUT, check=True)
    manifest = {"zi": str(zi), "annex": str(repo), "cases": {"loader": {}}}
    # Local paths belong to disposable container state, not the exported report.
    manifest_path = Path(os.environ["TMPDIR"]) / "loader-inputs.json"
    manifest_path.write_text(json.dumps(manifest))
    subprocess.run(["python3", "benchmarks/run.py", str(manifest_path), "--case", "loader",
                    "--runner-image", os.environ["ZD_RUNNER_IMAGE"], "--samples", str(args.samples),
                    "--warmups", str(args.warmups), "--output", str(output / "comparison.json")], check=True)
