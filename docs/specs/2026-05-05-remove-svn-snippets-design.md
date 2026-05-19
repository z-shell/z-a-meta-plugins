# Remove SVN-Dependent Snippets & Expand @ohmyzsh-lib

**Date:** 2026-05-05
**Status:** Approved

## Context

GitHub dropped SVN support. Zi's `svn` ice relies on GitHub's SVN API to checkout directories, which no longer works. Two meta-plugins in `z-a-meta-plugins` depended on this:

- `@prezto` — loaded `PZTM::archive`, `PZTM::directory`, `PZTM::utility` as SVN-fetched directory snippets.
- `@ohmyzsh-svn-lib` — loaded `OMZ::lib` as an SVN-fetched directory with `multisrc`.

Both are dropped entirely. `@ohmyzsh-lib` (individual `OMZL::*` files, no SVN) is the correct replacement path for OMZ library files. There is no replacement for `@prezto`.

Additionally, `@ohmyzsh-lib` was missing 5 commonly useful OMZ lib files and was entirely absent from the wiki documentation.

## Decisions

- **Drop `@prezto`**: no viable non-SVN replacement for directory-based Prezto module loading.
- **Drop `@ohmyzsh-svn-lib`**: fully covered by the `@ohmyzsh-lib` approach using individual `OMZL::*` file snippets.
- **Expand `@ohmyzsh-lib`**: add 5 additional `OMZL::*` entries with clear positive effects and no surprising side effects.
- **Document `@ohmyzsh-lib`** in the wiki meta-plugins table (was absent).
- **No changes** to migration docs, commands docs, or any other wiki page — those reference single-file raw URL snippets which still work correctly.

## Changes

### 1. `z-a-meta-plugins.plugin.zsh`

#### `zi_annex_meta_plugins_map` — remove two entries

```zsh
# REMOVE:
prezto      "PZTM::archive PZTM::directory PZTM::utility"

# REMOVE (including comment):
# Oh-My-Zsh library using subversion
ohmyzsh-svn-lib "OMZ::lib"
```

#### `zi_annex_meta_plugins_map` — update `ohmyzsh-lib` entry

```zsh
# BEFORE:
ohmyzsh-lib "OMZL::git OMZL::history OMZL::vcs_info OMZL::clipboard OMZL::completion OMZL::theme-and-appearance OMZL::prompt_info_functions"

# AFTER (adds termsupport, key-bindings, compfix, directories, functions):
ohmyzsh-lib "OMZL::git OMZL::history OMZL::vcs_info OMZL::clipboard OMZL::completion OMZL::theme-and-appearance OMZL::prompt_info_functions OMZL::termsupport OMZL::key-bindings OMZL::compfix OMZL::directories OMZL::functions"
```

#### `zi_annex_meta_plugins_config_map` snippet block — remove Prezto entries and `OMZ::lib`

```zsh
# REMOVE these entries from the appended snippet block:
PZTM::archive       "$_std svn silent nocompile"
PZTM::directory     "$_std"
PZTM::utility       "$_std"
OMZ::lib            "$_std svn multisrc'...' pick'/dev/null'"
```

#### `zi_annex_meta_plugins_config_map` snippet block — add 5 new OMZL entries

```zsh
# ADD:
OMZL::termsupport           "$_std"
OMZL::key-bindings          "$_std"
OMZL::compfix               "$_std"
OMZL::directories           "$_std"
OMZL::functions             "$_std"
```

### 2. `wiki/ecosystem/annexes/2_meta_plugins.mdx`

#### Available meta-plugins table

- **Remove** the `@prezto` row.
- **Add** an `@ohmyzsh-lib` row documenting all 12 `OMZL::*` entries.

```markdown
| @ohmyzsh-lib | OMZL::git, OMZL::history, OMZL::vcs_info, OMZL::clipboard, OMZL::completion, OMZL::theme-and-appearance, OMZL::prompt_info_functions, OMZL::termsupport, OMZL::key-bindings, OMZL::compfix, OMZL::directories, OMZL::functions |
```

## Files Touched

| File                                                       | Change                                       |
| ---------------------------------------------------------- | -------------------------------------------- |
| `zsh-plugins/z-a-meta-plugins/z-a-meta-plugins.plugin.zsh` | Remove SVN entries, expand `@ohmyzsh-lib`    |
| `wiki/ecosystem/annexes/2_meta_plugins.mdx`                | Remove `@prezto` row, add `@ohmyzsh-lib` row |

## Out of Scope

- `wiki/docs/getting_started/03_migration.mdx` — single-file OMZL/OMZP snippets, unaffected.
- `wiki/docs/guides/syntax/` and `wiki/docs/guides/01_commands.mdx` — shorthand syntax docs, unaffected.
- `wiki/docusaurus.config.ts` — generic keyword mention of "prezto", not functional.
