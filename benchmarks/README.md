# Group benchmarks

These benchmarks report performance and reject broken behavior. A median regression greater than 10% or p95 regression greater than 15% requests review without failing the job, following [ADR-0024](https://github.com/z-shell/.github/blob/main/decisions/0024-benchmarks-observed-not-gated.md). Use a quiet runner and keep native and container results separate. Python 3 drives the trials; the workload runs in Zsh.

| Case          | Group issues | Measured operation                                        |
| ------------- | ------------ | --------------------------------------------------------- |
| `loader`      | #60          | Shared dispatch of a minimal installed plugin             |
| `editor`      | #62          | Completion, autosuggestions and syntax highlighting       |
| `editor-fast` | #63          | The alternative editor profile with F-Sy-H                |
| `fzf`         | #66          | Native fzf integration and filtering 10,000 fixed lines   |
| `pyenv`       | #73          | Native pyenv initialization and system-version resolution |

Every case reports group loading, first `precmd` setup and repeated loading.
Repeat loading must preserve PATH, fpath, registered plugins, hook arrays,
widgets and queued work. The loader fixture also asserts that its entrypoint
runs exactly once. Functional failures invalidate timings, including a common
network command attempted during a trial.

## Prepare inputs outside the benchmark

Use isolated Zi installations populated with the desired groups and exact
upstream revisions. Finish all cloning, downloads and builds first. Supply
Zi's `HOME_DIR` as `state`, not the checkout containing `zi.zsh`. The runner
copies only the required plugins into disposable state; it does not update
upstreams, install compilers or modify the original installation.

For fzf and pyenv, also provide the first-party package-definition checkouts.
The fixture substitutes their local JSON path while preserving the selected
profile. The native fzf profile must already have its matching executable and
shell integration installed. No user startup files or environment secrets are
forwarded. Input manifests contain local paths and should stay out of commits.

Example `candidate.json` (replace paths with your prepared checkouts):

```json
{
  "zi": "/checkouts/zi",
  "annex": "/checkouts/z-a-meta-plugins",
  "cases": {
    "loader": {},
    "editor": { "state": "/fixtures/editor-data" },
    "editor-fast": { "state": "/fixtures/editor-data" },
    "fzf": {
      "state": "/fixtures/fzf-data",
      "package": "/checkouts/fzf"
    },
    "pyenv": {
      "state": "/fixtures/pyenv-data",
      "package": "/checkouts/pyenv"
    }
  }
}
```

```sh
python3 benchmarks/run.py candidate.json --runner-image workstation-image-v1 \
  --output candidate-results.json
python3 benchmarks/run.py candidate.json --baseline baseline.json \
  --mode recipes --runner-image workstation-image-v1 --output comparison.json
```

`recipes` mode requires identical Zi and installed upstream bytes. Annex and
package definitions may differ. `upstream` mode requires identical Zi, annex
and package definitions; installed upstream snapshots may differ. Both reject
changed group membership. To test a Zi change itself, design a separate
comparison: these modes deliberately keep the manager fixed.

Every comparison measures baseline, candidate and a second baseline copy as an A/A noise control in the same run. With no `--baseline`, the candidate manifest supplies all three copies for a self-comparison. Six rotating permutations balance variant order and positions, with five discarded warmups and 30 samples per variant by default. Select a subset with repeated `--case` arguments. Each trial starts a fresh interactive Zsh process and reuses its variant's disposable warmed caches. Provisioning, shell process launch and container startup are outside the reported group timings.

Supply `--runner-image` with a stable, non-sensitive host image identifier outside CI. GitHub-hosted CI defaults to `ImageOS-ImageVersion`. The recorded identities include actual Zsh version, architecture, CPU model, host image, and sample/warmup counts; all three variants must match. Do not compare reports from different host images or mix native and container reports.

## Run in z-shell/zd

The same fixture runs in the existing [zd](https://github.com/z-shell/zd)
container without changing zd or adding Python to its image. Pull an image
separately, resolve its immutable digest, then pass it to `--zd-image`:

```sh
docker pull ghcr.io/z-shell/zd:latest
docker image inspect ghcr.io/z-shell/zd:latest --format '{{index .RepoDigests 0}}'
python3 benchmarks/run.py candidate.json --baseline baseline.json \
  --zd-image ghcr.io/z-shell/zd@sha256:REPLACE_WITH_FULL_DIGEST \
  --runner-image workstation-image-v1 --output zd-comparison.json
```

Trials use `--network=none`, a read-only container filesystem and source mounts,
and disposable writable benchmark state. The image must already exist locally;
there is no implicit pull. The image digest and actual container Zsh version
are recorded. Image architecture must match prepared executable artifacts.
Native mode blocks common download commands through PATH; it is not a network
sandbox. The zd reusable workflow remains useful for correctness and Zsh
compatibility checks alongside these measurements.

## Interpret and verify results

Reports use the ADR-0024 `schema_version: 1` contract. Each metric becomes a separate case, such as `loader.repeat_ms`, under `cases` and `control`. Each row retains raw samples, median, nearest-rank p95, minimum, count, and absolute/percentage median and p95 changes. The control row compares the first baseline with its second copy. `flagged` lists candidate regressions; control flags remain visible separately as noise evidence. Percent changes are `null` when the baseline statistic is zero, and cannot produce a percentage flag.

Only reports with `status: complete` and `comparable: true` are valid evidence. Failed trials record the case, variant and phase code, add case names to `failed`, and fail the command. Incomplete reports are retained for diagnosis, with no accepted timing flags. Source identities are SHA-256 content identities covering consumed source bytes, prepared upstream inputs, available Git revisions and command versions. `inputs` retains this provenance, while the driver and fixture have separate fingerprints. The report records dirty source bytes without publishing checkout paths or inherited environment values.

Timers use Zsh's documented
[`EPOCHREALTIME`](https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fdatetime-Module).
Clock adjustments invalidate the run. `repeat_ms` is the per-call average of
100 loads; pyenv's operation is an average of ten resolutions. Their p95 is
across batch averages, not individual keystrokes. Editor `precmd_ms` measures
setup hooks explicitly, not time to a rendered prompt or interactive widget
latency. Ignore `operation_ms` for cases without a separate operation.

```sh
python3 tests/test_benchmark_report.py
python3 tests/benchmark-check.py --zi /checkouts/zi
```

This check runs an A/A control, injects a known delay into a disposable annex,
verifies the reported slowdown, rejects incompatible comparisons, and confirms
functional failures cannot become accepted timings.

Start with artifacts, job summaries and review notices. Timing flags never block merging; noisy A/A controls call for another run on a quieter host. A future gate needs a stable runner noise envelope plus meaningful absolute and relative limits. The `benchmark-loader.yml` workflow compares PR base and head for shared loading, using a fixed Zi commit and native/zd jobs. It measures all three variants on the same runner and uploads the canonical JSON, including incomplete reports. GitHub notices and a job summary expose candidate flags alongside the A/A noise. Manual dispatch runs a self-comparison. The initial baseline may fail because it predates the annex's successful empty-replacement fix.

Editor, fzf and pyenv CI comparisons and scheduled upstream detection can call
this same runner after prerequisite package revisions and fixture provisioning
are published. No schedule or automatic dependency update is configured.
Installation/update cost, interactive latency, and the remaining groups need their own controlled fixtures before coverage is claimed.

## Controlled profile pilot

The zd controlled `runtime` profile provides the selected Zsh runtime and Python without build tooling. Prepare its immutable image and a pinned Zi Git checkout before the run, then use the repository-owned entrypoint:

```sh
python3 /path/to/zd/bin/zd run \
  --image "$ZD_IMAGE" --profile runtime --source . \
  --input zi=/checkouts/zi --output /evidence/annex --mode benchmark \
  --cpuset "$BENCHMARK_CPU" -- python3 scripts/zd-check.py --benchmark
```

The entrypoint runs every self-contained Zsh test, native source syntax checks, report-contract tests and the existing sensitivity/failure qualification before the full loader self-comparison. The prepared Zi input is copied without Git metadata; zd records its original revision and content identity in `execution.json`, while the benchmark identifies consumed bytes. Raw samples remain in `comparison.json`, accepted by the organization `benchmark-report` action. Tests and sensitivity output are preserved separately. Without `--benchmark`, no Zi fixture is required.

This pilot measures only the loader fixture. It does not provision editor, fzf or pyenv groups, add zpmod, or claim interactive latency coverage. Container startup is outside the reported workload timers. Keep native platform checks and quieter-host confirmation when A/A controls show noise. The legacy `--zd-image` trial mode remains available for existing callers; this entrypoint instead runs the complete repository command inside one controlled container.

The manual `Controlled Zd Validation` workflow prepares the fixed Zi checkout and calls the shared `run-zd` and `benchmark-report` actions. The workflow pins published organization/zd commit SHAs; dispatch selects a qualified registry image digest. Both prerequisite pins select reviewed merge commits. To qualify a draft before the new workflow exists on main, dispatch the existing `Loader Benchmarks` workflow on its branch and supply `controlled-image`; it calls the same controlled workflow and skips the native/legacy comparison for that explicit selection. An empty input keeps the existing native/legacy jobs. The caller supplies no mutable fallback or unpublished default pin. Promote the caller to an automatic immutable action reference only after the shared implementation and images are published and hosted qualification passes.
