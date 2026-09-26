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

METRICS = ("load_ms", "precmd_ms", "repeat_ms", "operation_ms")

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
    return {"median": statistics.median(samples), "p95": sorted(samples)[math.ceil(.95 * len(samples)) - 1], "min": min(samples), "count": len(samples), "samples": samples}


def prepare(spec, case, root):
    config = spec["cases"][case]
    metadata = {"zi": source_fingerprint(spec["zi"], "zi"), "annex": source_fingerprint(spec["annex"], "annex"), "upstreams": {}, "upstream_revisions": {}}
    for kind in ("zi", "annex"):
        if (Path(spec[kind]) / ".git").exists():
            metadata[kind + "_revision"] = subprocess.check_output(["git", "-C", spec[kind], "rev-parse", "HEAD"], text=True).strip()
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
    if not isinstance(metrics, dict) or set(metrics) != set(METRICS) or not all(type(v) in (int, float) and math.isfinite(v) and v >= 0 for v in metrics.values()):
        raise ValueError("invalid timer result")
    versions = [line[8:] for line in stdout.splitlines() if line.startswith("VERSION ")]
    if len(versions) != 1:
        raise ValueError("missing upstream version")
    return metrics, members[0], runtime[0], versions[0]


def comparison_row(before, after):
    change = {}
    for metric in ("median", "p95"):
        delta = after[metric] - before[metric]
        change[metric + "_delta_ms"] = delta
        change[metric + "_delta_percent"] = 100 * delta / before[metric] if before[metric] else None
    flag = any(change[key] is not None and change[key] > limit for key, limit in
               (("median_delta_percent", 10), ("p95_delta_percent", 15)))
    return {"results": {"baseline": before, "candidate": after}, "change": change, "flag": flag}


def trial_order(iteration):
    labels = ["baseline", "candidate", "control"]
    rotation = iteration % 3
    labels = labels[rotation:] + labels[:rotation]
    return labels if iteration // 3 % 2 == 0 else list(reversed(labels))


def cpu_identity():
    cpuinfo = Path("/proc/cpuinfo")
    if cpuinfo.is_file():
        for line in cpuinfo.read_text().splitlines():
            if line.startswith("model name"):
                return line.partition(":")[2].strip()
    return platform.processor() or platform.machine()


def run(args):
    candidate = json.loads(args.candidate.read_text())
    baseline = json.loads(args.baseline.read_text()) if args.baseline else candidate
    specs = {"baseline": baseline, "candidate": candidate, "control": baseline}
    cases = args.case or list(candidate["cases"])
    if not cases or len(set(cases)) != len(cases) or any(case not in MEMBERS or any(case not in spec["cases"] for spec in specs.values()) for case in cases):
        raise ValueError("all variants must define each selected supported case exactly once")
    report = {
        "schema_version": 1, "status": "incomplete", "comparable": False,
        "mode": args.mode, "runtime": args.zd_image or "native",
        "timer": "zsh EPOCHREALTIME elapsed milliseconds; clock steps invalidate the run",
        "runner_sha256": fingerprint(Path(__file__)),
        "fixture_sha256": fingerprint(Path(__file__).with_name("sample.zsh")),
        "thresholds": {"median_percent": 10, "p95_percent": 15},
        "cases": {}, "control": {}, "inputs": {}, "flagged": [], "failed": [],
    }
    identities = {}
    for label in specs:
        identities[label] = {
            "label": label, "source_revision": "pending",
            "environment": {"zsh_version": "pending", "architecture": "pending", "cpu": cpu_identity(),
                            "runner_image": args.runner_image + (";" + args.zd_image if args.zd_image else "")},
            "workload": {"warmups": args.warmups, "samples": args.samples},
        }
    report.update(baseline=identities["baseline"], candidate=identities["candidate"], control_identity=identities["control"])

    def write_report():
        args.output.write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")

    write_report()
    with tempfile.TemporaryDirectory(prefix="meta-benchmark-") as temporary:
        for case in cases:
            roots, metadata, samples = {}, {}, {}
            active_label = "baseline"
            try:
                for label, spec in specs.items():
                    active_label = label
                    root = Path(temporary) / case / label
                    root.mkdir(parents=True)
                    roots[label] = root
                    metadata[label] = prepare(spec, case, root)
                    samples[label] = {metric: [] for metric in METRICS}
                report["inputs"][case] = metadata
                fixed = ("zi", "upstreams") if args.mode == "recipes" else ("zi", "annex", "package")
                active_label = "candidate"
                if any(metadata["baseline"].get(key) != metadata["candidate"].get(key) for key in fixed):
                    raise ValueError(f"{case}: comparison changes inputs required fixed in {args.mode} mode")
                active_label = "control"
                if metadata["control"] != metadata["baseline"]:
                    raise ValueError("control is not a second copy of the baseline")
                membership = None
                for iteration in range(args.warmups + args.samples):
                    # Six permutations balance positions and pairwise order.
                    for label in trial_order(iteration):
                        active_label = label
                        metrics, members, runtime, version = trial(specs[label], case, roots[label], args.zd_image)
                        if not isinstance(metrics, dict) or set(metrics) != set(METRICS) or any(type(v) not in (int, float) or not math.isfinite(v) or v < 0 for v in metrics.values()):
                            raise ValueError("invalid or incomplete timer result")
                        if "shell" in report and report["shell"] != runtime:
                            raise ValueError("shell changed during comparison")
                        runtime_parts = runtime.split()
                        if len(runtime_parts) != 3:
                            raise ValueError("invalid shell identity")
                        report["shell"] = runtime
                        identities[label]["environment"].update(zsh_version=runtime_parts[0], architecture=runtime_parts[2])
                        if "version" in metadata[label] and metadata[label]["version"] != version:
                            raise ValueError("upstream version changed during trials")
                        metadata[label]["version"] = version
                        if membership is not None and membership != members:
                            raise ValueError(f"{case}: group membership differs; timings are not comparable")
                        membership = members
                        if iteration >= args.warmups:
                            for metric, value in metrics.items():
                                samples[label][metric].append(value)
                for label, spec in specs.items():
                    active_label = label
                    if any(source_fingerprint(spec[key], key) != metadata[label][key] for key in ("zi", "annex")):
                        raise ValueError("source changed during trials; results invalid")
                for metric in METRICS:
                    key = case + "." + metric
                    base = summary(samples["baseline"][metric])
                    report["cases"][key] = comparison_row(base, summary(samples["candidate"][metric]))
                    report["control"][key] = comparison_row(base, summary(samples["control"][metric]))
                for label in specs:
                    # Content identity covers dirty source and every prepared input.
                    inputs = {name: values[label] for name, values in report["inputs"].items()}
                    identities[label]["source_revision"] = "sha256:" + hashlib.sha256(json.dumps(inputs, sort_keys=True).encode()).hexdigest()
                print(f"{case}: {args.samples} valid samples per variant plus A/A control", flush=True)
            except (OSError, RuntimeError, ValueError, subprocess.TimeoutExpired) as error:
                message = "trial timed out" if isinstance(error, subprocess.TimeoutExpired) else "input or process I/O failed" if isinstance(error, OSError) else str(error)
                report["failure"] = {"case": case, "variant": active_label, "error": message}
                for metric in METRICS:
                    key = case + "." + metric
                    target = "control" if active_label == "control" else "cases"
                    side = "baseline" if active_label == "baseline" else "candidate"
                    report[target][key] = {"failure": {"baseline": None, "candidate": None}}
                    report[target][key]["failure"][side] = message
                    report["failed"].append(key)
                # Partial reports cannot present earlier rows as accepted evidence.
                for section in ("cases", "control"):
                    for row in report[section].values():
                        if "flag" in row:
                            row["flag"] = None
                write_report()
                raise
            write_report()
    report["comparable"] = all(identities[label]["environment"] == identities["baseline"]["environment"] and
                               identities[label]["workload"] == identities["baseline"]["workload"] for label in ("candidate", "control"))
    if not report["comparable"]:
        write_report()
        raise ValueError("environment or workload identities are incompatible")
    report["flagged"] = [key for key, row in report["cases"].items() if row["flag"]]
    report["status"] = "complete"
    write_report()
    for section in ("cases", "control"):
        for key, row in report[section].items():
            if row["flag"]:
                prefix = "::notice::" if os.environ.get("GITHUB_ACTIONS") == "true" else "review flag: "
                print(f"{prefix}{section} {key} exceeds median 10% or p95 15%; timing does not fail the run")
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        lines = ["### Loader benchmark comparison", "", "Timing flags request review and never fail the job. A/A flags indicate runner noise.", "",
                 "| Case | Median change (%) | p95 change (%) | Review | A/A median (%) | A/A p95 (%) | A/A review |",
                 "| --- | ---: | ---: | --- | ---: | ---: | --- |"]
        def percent(value):
            return "n/a" if value is None else f"{value:+.2f}"
        for key, row in report["cases"].items():
            control = report["control"][key]
            values = [key, percent(row["change"]["median_delta_percent"]), percent(row["change"]["p95_delta_percent"]), str(row["flag"]),
                      percent(control["change"]["median_delta_percent"]), percent(control["change"]["p95_delta_percent"]), str(control["flag"])]
            lines.append("| " + " | ".join(values) + " |")
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as stream:
            stream.write("\n".join(lines) + "\n")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path, help="JSON with zi, annex and cases mapping to prepared state/package paths")
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--mode", choices=("recipes", "upstream"), default="recipes")
    parser.add_argument("--case", choices=tuple(MEMBERS), action="append")
    parser.add_argument("--samples", type=int, default=30)
    parser.add_argument("--warmups", type=int, default=5)
    parser.add_argument("--zd-image", help="Already-pulled zd image with immutable @sha256 digest")
    parser.add_argument("--runner-image", default="-".join(filter(None, (os.environ.get("ImageOS"), os.environ.get("ImageVersion")))),
                        help="Stable host or runner image identity; defaults to GitHub ImageOS-ImageVersion")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.samples < 2 or args.warmups < 1:
        parser.error("use at least two samples and one warmup")
    if not args.runner_image.strip():
        parser.error("--runner-image is required outside an identified CI runner")
    if args.zd_image and (not args.zd_image.startswith("ghcr.io/z-shell/zd@sha256:") or len(args.zd_image.rsplit(":", 1)[-1]) != 64 or any(c not in "0123456789abcdef" for c in args.zd_image.rsplit(":", 1)[-1])):
        parser.error("zd image must be pinned by full digest")
    run(args)


if __name__ == "__main__":
    main()
