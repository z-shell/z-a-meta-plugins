# Shared lint pilot

The [pilot workflow](../.github/workflows/zsh-lint-pilot.yml) qualifies the shared reporting wrapper under [issue #103](https://github.com/z-shell/z-a-meta-plugins/issues/103). It runs on every pull request targeting `main`, including documentation-only changes and forks, and every push to `main`.

The explicit [configuration](../zsh-lint.json) retains the repository's Zsh 5.9.2 compatibility floor and these source profiles:

| Source                                              | Profile             |
| --------------------------------------------------- | ------------------- |
| `z-a-meta-plugins.plugin.zsh`                       | `sourced-library`   |
| `functions/_z_a_meta_plugins_before_load_handler`   | `autoload-function` |
| `functions/_z_a_meta_plugins_meta_cmd`              | `autoload-function` |
| `functions/_z_a_meta_plugins_meta_cmd_help_handler` | `autoload-function` |

The directory input includes every file under `functions/`; additions therefore need the same source-profile review. Tests and benchmarks keep their existing validation and are outside this analyzer inventory.

The workflow pins the reviewed shared implementation at `af725f0ad9c7b24dd4f4527e582ade2eb8e9ea7b` and analyzer release v1.3.0 at `999cb76cc65ef6af56c0ae65ab0f3622eb527944`. Its artifact records both revisions, the resolved inventory, diagnostics, stderr and the outcome. Artifact retention is 14 days; lasting qualification evidence belongs on issue #103.

`mode: observe` reports semantic findings without failing the job. Parser failures, malformed configuration and infrastructure failures still fail. The caller grants only `contents: read`, passes no secrets and uses the ordinary `pull_request` event. This pilot is advisory; any required-check change needs separate approval after hosted check-name, trigger and fork qualification.

The existing released lint caller and native syntax, compilation and functional workflows remain active. The released caller also participates in [the separate workflow-release qualification](https://github.com/z-shell/.github/issues/543). Do not replace its pin as part of this observation pilot. Roll back this enrollment by reverting the pilot workflow and this guide; the prior validation remains in place.
