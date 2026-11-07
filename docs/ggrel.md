# `ggrel`

Full release automation pipeline. Consumes release notes (from [`gemini-release-notes`](gemini-release-notes.md), a file, or inline text), displays an interactive release preview, executes pre-release test and build hooks, updates the version file, creates an annotated Git tag, pushes the branch and tag to `origin`, and publishes the release to GitHub via the `gh` CLI.

---

## Synopsis

```bash
ggrel <version> [options]
```

---

## Arguments

| Argument | Description |
| :--- | :--- |
| `<version>` | Target release version (e.g. `1.2.0` or `v1.2.0`). Required. |

---

## Release Notes Options (Required)

`ggrel` strictly requires release notes and does not auto-generate them internally. Provide them via one of the following methods:

| Flag | Description |
| :--- | :--- |
| `-f, --notes-file <file>` | Reads release notes from a file path. Specify `-` to read from standard input. |
| `--notes <text>` | Passes release notes directly as an inline string. |
| *(stdin pipe)* | Pipe release notes directly via stdin (e.g. `gemini-release-notes | ggrel 1.2.0`). |

---

## Execution Modes

| Flag | Description |
| :--- | :--- |
| `-n`, `--dry-run`, `--preview` | Renders the complete release preview and release notes without making commits, tags, pushes, or publishing releases. |

---

## Customization Options

| Flag | Description |
| :--- | :--- |
| `--app-name <name>` | Sets application name used in release titles (defaults to the repository directory name). |
| `--test-cmd <cmd>` | Shell command to execute for pre-release tests (e.g. `npm test` or `cargo test`). Aborts release if tests fail. |
| `--build-cmd <cmd>` | Shell command to build release artifacts before tagging (e.g. `npm run build`). Aborts release if build fails. |
| `-a`, `--attach <file>` | Release asset to upload to the GitHub release via `gh` (repeatable). |
| `-h`, `--help` | Displays usage instructions and available options. |

*(Note: In commands like `--test-cmd` and `--build-cmd`, `${target_version}` and `$target_version` placeholders are dynamically replaced with the release version).*

---

## Configuration Hooks (`.release.sh`)

Instead of repeatedly specifying CLI options for every release, you can create a `.release.sh` (or `.git-release.sh`) file in the root of the repository. `ggrel` automatically sources this file if present.

The hook is executable code: only run `ggrel` (including `--dry-run`) in repositories you trust. `ggrel --help` and invocations with invalid arguments never load the hook. The hook is sourced in a subshell (its output goes to stderr) and only the variables listed below are imported, so it cannot alter `ggrel`'s internal state.

Supported variables:
- `APP_NAME`: Application name used in release titles and tags.
- `TEST_CMD`: Shell command for pre-release test execution.
- `BUILD_CMD`: Shell command to build or package release assets before tagging.
- `RELEASE_ASSETS`: Bash array of asset file paths to upload to the GitHub release. Supports `${target_version}` placeholders (use single quotes to avoid premature expansion).

Example `.release.sh`:
```bash
#!/usr/bin/env bash
APP_NAME="my-app"
TEST_CMD="npm test"
BUILD_CMD='git archive --format=tar.gz -o "dist/my-app-${target_version}.tar.gz" HEAD'
RELEASE_ASSETS=(
    'dist/my-app-${target_version}.tar.gz'
    "install.sh"
)
```

Command-line flags always take precedence over values defined in the configuration hook (`--attach` assets are appended to `RELEASE_ASSETS`).

Prefer building archives from the commit (`git archive … HEAD`) rather than globbing the working tree: globs such as `my-app-*` also match previously built archives and untracked files.

---

## Version File (`VERSION`)

`ggrel` always manages a `VERSION` file in the root of the repository. You never need to pass or configure a version file path.
- If `VERSION` does not exist, `ggrel` creates it during the release (dry runs never touch it).
- During the release process, `ggrel` updates `VERSION` to the user-specified target version, stages it (`git add VERSION`), and commits it as `chore(release): bump version to v<version>` before creating the release tag.

---

## Mandatory Confirmation & Safety Guards

1. **Clean Worktree**: Refuses to release when tracked files have staged or unstaged changes (`git status --porcelain --untracked-files=no`), so built artifacts match the tagged commit.
2. **Tag Existence**: Confirms tag `v<version>` does not already exist.
3. **Interactive Confirmation**: Always prompts for user confirmation (`Proceed with release v<version>? Type 'yes' to continue: `) unless running in `--dry-run`. Even when release notes are piped from stdin, `ggrel` safely reads confirmation from `/dev/tty`.
4. **Mandatory GitHub & Git Push**: Creating annotated tags, pushing branches/tags to `origin`, and creating GitHub releases via `gh` are always performed.

---

## Dependencies

- `git`
- `gh` (GitHub CLI)

---

## Examples

### Complete Pipeline via Pipe
```bash
gemini-release-notes | ggrel 1.2.0
```

### Dry Run Preview
```bash
gemini-release-notes | ggrel 1.2.0 --dry-run
```

### Release from Pre-generated Notes File
```bash
ggrel 1.2.0 -f release_notes.md
```

### Full Release with Tests, Build, and Multiple Artifacts
The `-a` (or `--attach`) flag is repeatable. You can attach multiple asset files such as `.zip`, `.tar.gz`, and `.dmg`:

```bash
gemini-release-notes | ggrel 1.2.0 \
  --test-cmd "npm test" \
  --build-cmd "npm run build" \
  -a dist/app-1.2.0.zip \
  -a dist/app-1.2.0.tar.gz \
  -a dist/app-1.2.0.dmg
```

You can also use the `${target_version}` placeholder in artifact paths, which dynamically resolves to the target release version:

```bash
gemini-release-notes | ggrel 1.2.0 \
  --test-cmd "make test" \
  --build-cmd "make build" \
  -a "dist/app-${target_version}.zip" \
  -a "dist/app-${target_version}.tar.gz" \
  -a "dist/app-${target_version}.dmg"
```
