# Group benchmarks

These benchmarks report performance and reject broken behavior. They do not
impose timing thresholds. Use a quiet runner and keep native and container
results separate. Python 3 drives the trials; the workload runs in Zsh.

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
python3 benchmarks/run.py candidate.json --output candidate-results.json
python3 benchmarks/run.py candidate.json --baseline baseline.json \
  --mode recipes --output comparison.json
```

`recipes` mode requires identical Zi and installed upstream bytes. Annex and
package definitions may differ. `upstream` mode requires identical Zi, annex
and package definitions; installed upstream snapshots may differ. Both reject
changed group membership. To test a Zi change itself, design a separate
comparison: these modes deliberately keep the manager fixed.

Use the same manifest on both sides for an A/A noise control. Order alternates
between variants, with five discarded warmups and 30 samples by default.
Select a subset with repeated `--case` arguments. Each trial starts a fresh
interactive Zsh process and reuses its variant's disposable warmed caches.
Provisioning, shell process launch and container startup are outside the
reported group timings.

## Run in z-shell/zd

The same fixture runs in the existing [zd](https://github.com/z-shell/zd)
container without changing zd or adding Python to its image. Pull an image
separately, resolve its immutable digest, then pass it to `--zd-image`:

```sh
docker pull ghcr.io/z-shell/zd:latest
docker image inspect ghcr.io/z-shell/zd:latest --format '{{index .RepoDigests 0}}'
python3 benchmarks/run.py candidate.json --baseline baseline.json \
  --zd-image ghcr.io/z-shell/zd@sha256:REPLACE_WITH_FULL_DIGEST \
  --output zd-comparison.json
```

Trials use `--network=none`, a read-only container filesystem and source mounts,
and disposable writable benchmark state. The image must already exist locally;
there is no implicit pull. The image digest and actual container Zsh version
are recorded. Image architecture must match prepared executable artifacts.
Native mode blocks common download commands through PATH; it is not a network
sandbox. The zd reusable workflow remains useful for correctness and Zsh
compatibility checks alongside these measurements.

## Interpret and verify results

JSON retains raw samples, median, nearest-rank p95, absolute/percentage median
changes, source fingerprints, available Git revisions and command versions.
Only reports with `status: complete` are valid. Failed trials record the case,
variant and phase code. The driver and fixture are fingerprinted too. Results
contain no source checkout paths or inherited environment values.

Timers use Zsh's documented
[`EPOCHREALTIME`](https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fdatetime-Module).
Clock adjustments invalidate the run. `repeat_ms` is the per-call average of
100 loads; pyenv's operation is an average of ten resolutions. Their p95 is
across batch averages, not individual keystrokes. Editor `precmd_ms` measures
setup hooks explicitly, not time to a rendered prompt or interactive widget
latency. Ignore `operation_ms` for cases without a separate operation.

```sh
python3 tests/benchmark-check.py --zi /checkouts/zi
```

This check runs an A/A control, injects a known delay into a disposable annex,
verifies the reported slowdown, rejects incompatible comparisons, and confirms
functional failures cannot become accepted timings.

Start with artifacts and review, not percentage-only CI gates. A future gate
needs a stable runner noise envelope plus meaningful absolute and relative
limits. The prepared `benchmark-loader.yml` workflow compares PR base and head for
shared loading, using a fixed Zi commit and native/zd jobs. Each comparison
runs both variants on the same runner; CI records its image identity. Use the
pinned zd image for a fixed userspace, and do not compare native results across
runner image changes. Manual dispatch
runs an A/A control. Timing changes never fail it, but broken behavior does;
artifacts preserve incomplete reports as well. The initial baseline may fail
because it predates the annex's successful empty-replacement fix.

Editor, fzf and pyenv CI comparisons and scheduled upstream detection can call
this same runner after prerequisite package revisions and fixture provisioning
are published. No schedule or automatic dependency update is configured.
The workflow has not been published or dispatched by this local work. Installation/update cost, interactive latency,
and the remaining groups need their own controlled fixtures before coverage
is claimed.
