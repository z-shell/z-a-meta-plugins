#!/usr/bin/env python3
"""Reporting-only group benchmarks; Python standard library, Zsh and prepared inputs."""
import argparse
import hashlib
import json
import math
import os
import platform
import shutil
import signal
import uuid
import statistics
import subprocess
import tempfile
from pathlib import Path

MEMBERS = {
    "loader": [],
    "editor": ["zsh-users---zsh-completions", "zsh-users---zsh-autosuggestions", "zsh-users---zsh-syntax-highlighting"],
    "editor-fast": ["zsh-users---zsh-completions", "zsh-users---zsh-autosuggestions", "z-shell---F-Sy-H"],
    "fzf": ["fzf"],
    "pyenv": ["pyenv"],
}
IGNORE = shutil.ignore_patterns(".git", ".trunk", "*.zwc", "__pycache__")


def fingerprint(path):
    """Hash consumed bytes, including dirty inputs; do not publish local paths."""
    path = Path(path)
    digest = hashlib.sha256()
    files = [path] if path.is_file() else sorted(path.rglob("*"))
    for file in files:
        if any(p in (".git", ".trunk", "__pycache__") for p in file.relative_to(path.parent if path.is_file() else path).parts):
            continue
        if file.is_file() and file.suffix != ".zwc":
            digest.update(str(file.relative_to(path.parent if path.is_file() else path)).encode())
            digest.update(b"\0" + file.read_bytes() + b"\0")
    return digest.hexdigest()


def source_fingerprint(path, kind):
    parts = ("zi.zsh", "lib/zsh") if kind == "zi" else ("z-a-meta-plugins.plugin.zsh", "functions")
    return hashlib.sha256("".join(fingerprint(Path(path) / part) for part in parts).encode()).hexdigest()


def summary(samples):
    return {"median": statistics.median(samples), "p95": sorted(samples)[math.ceil(.95 * len(samples)) - 1], "samples": samples}


def prepare(spec, case, root):
    config = spec["cases"][case]
    metadata = {"zi": source_fingerprint(spec["zi"], "zi"), "annex": source_fingerprint(spec["annex"], "annex"), "upstreams": {}, "upstream_revisions": {}}
    if case == "loader":
        plugin = root / "data/plugins/benchmark---fixture"
        (plugin / "._zi").mkdir(parents=True)
        (plugin / "fixture.plugin.zsh").write_text("(( ++BENCHMARK_LOAD_COUNT )); return 0\n")
    for name in MEMBERS[case]:
        source = Path(config["state"]) / "plugins" / name
        if not source.is_dir():
            raise ValueError(f"missing prepared plugin: {name}")
        metadata["upstreams"][name] = fingerprint(source)
        if (source / ".git").exists():
            metadata["upstream_revisions"][name] = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"], text=True).strip()
        shutil.copytree(source, root / "data/plugins" / name, ignore=IGNORE)
    if case in ("fzf", "pyenv"):
        source = Path(config["package"]) / "package.json"
        metadata["package"] = fingerprint(source)
        (root / "package").mkdir()
        shutil.copy2(source, root / "package/package.json")
    for name in ("home", "tmp", "deny"):
        (root / name).mkdir()
    (root / "items").write_text("".join(f"item-{i:05d}\n" for i in range(10000)))
    for name in ("curl", "wget", "lftp", "lynx", "git"):
        guard = root / "deny" / name
        passthrough = 'case "$1" in clone|fetch|pull|push|ls-remote) ;; *) exec /usr/bin/git "$@" ;; esac\n' if name == "git" else ""
        guard.write_text('#!/bin/sh\n' + passthrough + 'echo attempted > "$BENCHMARK_ROOT/network-attempt"\nexit 90\n')
        guard.chmod(0o755)
    return metadata


def trial(spec, case, root, image):
    fixture = Path(__file__).with_name("sample.zsh").resolve()
    env = {"PATH": "/usr/local/bin:/usr/bin:/bin", "HOME": str(root / "home"), "ZDOTDIR": str(root / "home"), "LANG": "C.UTF-8", "BENCHMARK_ROOT": str(root)}
    container = "meta-benchmark-" + uuid.uuid4().hex
    if image:
        command = ["docker", "run", "--rm", "--name", container, "--pull=never", "--network=none", "--read-only", "--tmpfs", "/tmp", "--user", f"{os.getuid()}:{os.getgid()}",
                   "-v", f"{root}:/benchmark", "-v", f"{Path(spec['zi']).resolve()}:/zi:ro", "-v", f"{Path(spec['annex']).resolve()}:/annex:ro", "-v", f"{fixture}:/sample.zsh:ro",
                   "-e", "BENCHMARK_ROOT=/benchmark", "-e", "HOME=/benchmark/home", "-e", "ZDOTDIR=/benchmark/home", "--entrypoint", "zsh", image,
                   "-dfi", "/sample.zsh", "/benchmark", "/zi", "/annex", case]
    else:
        command = ["zsh", "-dfi", str(fixture), str(root), str(Path(spec["zi"]).resolve()), str(Path(spec["annex"]).resolve()), case]
    process = subprocess.Popen(command, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, start_new_session=True)
    try:
        stdout, _ = process.communicate(timeout=60)
    except BaseException:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGKILL)
        process.wait()
        if image:
            subprocess.run(["docker", "rm", "-f", container], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=15)
        raise
    if process.returncode:
        # Logs can contain host paths or environment data; report only the phase code.
        raise RuntimeError(f"{case}: fixture failed with status {process.returncode}; no timings accepted")
    records = [line[7:] for line in stdout.splitlines() if line.startswith("RESULT ")]
    members = [line[8:] for line in stdout.splitlines() if line.startswith("MEMBERS ")]
    runtime = [line[8:] for line in stdout.splitlines() if line.startswith("RUNTIME ")]
    if len(records) != 1 or len(members) != 1 or len(runtime) != 1:
        raise ValueError("missing or ambiguous fixture result")
    metrics = json.loads(records[0])
    if not all(isinstance(v, (int, float)) and math.isfinite(v) and v >= 0 for v in metrics.values()):
        raise ValueError("invalid timer result")
    versions = [line[8:] for line in stdout.splitlines() if line.startswith("VERSION ")]
    if len(versions) != 1:
        raise ValueError("missing upstream version")
    return metrics, members[0], runtime[0], versions[0]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path, help="JSON with zi, annex and cases mapping to prepared state/package paths")
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--mode", choices=("recipes", "upstream"), default="recipes")
    parser.add_argument("--case", choices=tuple(MEMBERS), action="append")
    parser.add_argument("--samples", type=int, default=30)
    parser.add_argument("--warmups", type=int, default=5)
    parser.add_argument("--zd-image", help="Already-pulled zd image with immutable @sha256 digest")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.samples < 2 or args.warmups < 1:
        parser.error("use at least two samples and one warmup")
    if args.zd_image and (not args.zd_image.startswith("ghcr.io/z-shell/zd@sha256:") or len(args.zd_image.rsplit(":", 1)[-1]) != 64):
        parser.error("zd image must be pinned by full digest")
    specs = {"candidate": json.loads(args.candidate.read_text())}
    if args.baseline:
        specs = {"baseline": json.loads(args.baseline.read_text()), **specs}
    cases = args.case or list(specs["candidate"]["cases"])
    if not cases or any(case not in MEMBERS or any(case not in spec["cases"] for spec in specs.values()) for case in cases):
        parser.error("all variants must define each selected supported case")
    report = {"schema": 1, "status": "incomplete", "mode": args.mode, "runtime": args.zd_image or "native", "platform": {"system": platform.system(), "machine": platform.machine()},
              "timer": "zsh EPOCHREALTIME elapsed milliseconds; clock steps invalidate the run", "warmups": args.warmups, "runner_sha256": fingerprint(Path(__file__)), "fixture_sha256": fingerprint(Path(__file__).with_name("sample.zsh")), "cases": {}}
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    with tempfile.TemporaryDirectory(prefix="meta-benchmark-") as temporary:
        for case in cases:
            roots, metadata, samples = {}, {}, {}
            for label, spec in specs.items():
                root = Path(temporary) / case / label
                root.mkdir(parents=True)
                roots[label] = root
                metadata[label] = prepare(spec, case, root)
                samples[label] = {}
            if args.baseline:
                fixed = ("zi", "upstreams") if args.mode == "recipes" else ("zi", "annex", "package")
                if any(metadata["baseline"].get(key) != metadata["candidate"].get(key) for key in fixed):
                    raise ValueError(f"{case}: comparison changes inputs required fixed in {args.mode} mode")
            membership = None
            for iteration in range(args.warmups + args.samples):
                # Alternate order so one variant is not always measured first.
                order = list(specs) if iteration % 2 == 0 else list(reversed(specs))
                for label in order:
                    try:
                        metrics, members, runtime, version = trial(specs[label], case, roots[label], args.zd_image)
                    except (RuntimeError, ValueError, subprocess.TimeoutExpired) as error:
                        report["failure"] = {"case": case, "variant": label, "iteration": iteration, "error": str(error) if not isinstance(error, subprocess.TimeoutExpired) else "trial timed out"}
                        args.output.write_text(json.dumps(report, indent=2) + "\n")
                        raise
                    if "shell" in report and report["shell"] != runtime:
                        raise ValueError("shell changed during comparison")
                    report["shell"] = runtime
                    if "version" in metadata[label] and metadata[label]["version"] != version:
                        raise ValueError("upstream version changed during trials")
                    metadata[label]["version"] = version
                    if membership is not None and membership != members:
                        raise ValueError(f"{case}: group membership differs; timings are not comparable")
                    membership = members
                    if iteration >= args.warmups:
                        for metric, value in metrics.items():
                            samples[label].setdefault(metric, []).append(value)
            for label, spec in specs.items():
                if any(source_fingerprint(spec[key], key) != metadata[label][key] for key in ("zi", "annex")):
                    raise ValueError("source changed during trials; results invalid")
            row = {"members": membership, "inputs": metadata, "results": {label: {metric: summary(values) for metric, values in values_by_metric.items()} for label, values_by_metric in samples.items()}}
            if args.baseline:
                row["change"] = {}
                for metric, values in row["results"]["candidate"].items():
                    before = row["results"]["baseline"][metric]["median"]
                    delta = values["median"] - before
                    row["change"][metric] = {"median_delta_ms": delta, "median_delta_percent": 100 * delta / before if before else None}
            report["cases"][case] = row
            print(f"{case}: {args.samples} valid samples per variant", flush=True)
    report["status"] = "complete"
    args.output.write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
