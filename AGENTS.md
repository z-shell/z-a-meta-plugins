# AGENTS.md - z-shell/z-a-meta-plugins

AI agent orientation for this repository. Organization policy lives in [z-shell/.github](https://github.com/z-shell/.github); its `AGENTS.md`, `PATTERNS.md`, decisions, and runbooks apply here and this file only adds what is specific to the annex.

## What this repo is

`z-a-meta-plugins` is a Zi annex. Loading a label such as `@zsh-users` through Zi queues a curated group of plugins with a tested ice list for each member. It registers a `before-load` hook and the `skip''` ice, installs nothing itself, and is consumed directly from Git.

## Layout

| Path                                              | Purpose                                                                             |
| :------------------------------------------------ | :---------------------------------------------------------------------------------- |
| `z-a-meta-plugins.plugin.zsh`                     | Entry point: state parameters, the label catalog, member recipes, hook registration |
| `functions/_z_a_meta_plugins_before_load_handler` | The Zi hook: expansion, `skip''`, provisioning checks, notices                      |
| `functions/_z_a_meta_plugins_meta_cmd*`           | `zi meta` subcommand stubs, commented out and unregistered; see issue 96            |
| `tests/*.zsh`                                     | Self-contained tests; each stubs the Zi API and runs with `zsh -f`                  |
| `benchmarks/`                                     | Reporting-only loader timing guide and scripts                                      |
| `docs/README.md`                                  | The user-facing README; there is no root `README.md`                                |
| `zsh-lint.json`                                   | Analyzer profile and the compatibility floor (Zsh 5.9.2)                            |

## README

The README lives at `docs/README.md` and follows the organization README template, [templates/readme/zsh-plugin.md](https://github.com/z-shell/.github/blob/main/templates/readme/zsh-plugin.md), adapted for an annex the way the `create-readme` skill describes for the Zi Annexes archetype: document the registered ice, the hook, the Zi integration, and only the Zi installation path. Keep the required sections; `tests/readme-structure.zsh` fails when one is missing. Prose is one paragraph per line without hard wrapping. `docs/README.md` is the preferred README location in this organization (then `.github/README.md`, then the root); do not add a second README elsewhere.

The [wiki page](https://wiki.zshell.dev/ecosystem/annexes/meta-plugins) owns the full catalog table and the migration guide. The README links into it instead of duplicating it.

## Contracts the tests enforce

- Every label in `_z_a_meta_plugins_map` expands to real recipes, every recipe is selected by a label, and every label with a notice is anchored; `tests/catalog-consistency.zsh` is the check. The wiki catalog table is updated by hand in the same change.
- Each label in `_z_a_meta_plugins_state[migration-anchored]` needs a `#migrate-<label>` heading on the wiki page; no test reaches the wiki, so add the heading before the label.
- Deprecated and retired labels notify once per session and are never silently dropped from the catalog.
- Recipes parse natively; `tests/recipe-syntax.zsh` catches a broken ice list without a Zi checkout.

## Verification

Run the suite exactly as CI does, from the repository root:

```bash
zsh -f -c 'setopt err_exit; for t in tests/*.zsh; do print -r -- "== $t"; zsh -f "$t"; done'
```

Also run `zsh -n` on the entry point and every file under `functions/`, and `zsh-lint --config zsh-lint.json z-a-meta-plugins.plugin.zsh functions/*` when the analyzer is available.

## Conventions

- Zsh source follows the [Zsh Plugin Standard](https://wiki.zshell.dev/community/zsh_plugin_standard) and the organization [Zsh scripting instructions](https://github.com/z-shell/.github/blob/main/.github/instructions/zsh-scripting.instructions.md). The compatibility floor is Zsh 5.9.2.
- Work branches from `main` and pull requests target `main`; by convention (no workflow enforces it) use `feature-<id>`, `bug-<id>`, or `hotfix-<id>` branch names and [Conventional Commits](https://github.com/z-shell/.github/blob/main/decisions/0003-conventional-commits.md).
- A `Co-authored-by` trailer may credit a real human. Never credit a bot, AI agent, or automation as a co-author.
- Do not add network activity to the annex load path; loading a label only rewrites Zi's queue.
- Do not use U+2014 in new text; use a hyphen, colon, or separate sentence.
