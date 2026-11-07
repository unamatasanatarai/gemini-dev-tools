# `ggic`

Non-interactive Git commit workflow automation tool. Stages changes, generates a Conventional Commit message via [`gemini-commit-message`](gemini-commit-message.md), prints it, and commits immediately — there is no review or edit step.

> **Note:** By default `ggic` runs `git add --all`, so untracked files (including any secrets not covered by `.gitignore`) are committed **and** their contents are sent to the Gemini API as part of the diff. Use `--staged-only` to control exactly what is committed and sent. To change a generated message afterwards, use `git commit --amend` (before pushing).

---

## Synopsis

```bash
ggic [options]
```

---

## Options

| Flag | Description |
| :--- | :--- |
| `--push` | Automatically pushes the current branch to `origin` immediately following a successful commit. (Refuses to push if on a detached `HEAD`). |
| `--staged-only` | Skips automatic `git add --all` staging. Only generates a commit message for and commits currently staged modifications. |
| `-h`, `--help` | Displays usage instructions and available options. |

---

## Workflow Steps

1. **Pre-flight Checks**: Confirms that `git` is available, the working directory is inside a Git repository, and that changes exist.
2. **Auto-staging**: Runs `git add --all` unless `--staged-only` is provided.
3. **Generation**: Invokes `gemini-commit-message` with fallback rotation across configured models.
4. **Display**: Prints the generated commit message (no confirmation prompt).
5. **Commit**: Runs `git commit -F -` with the generated message.
6. **Push (Optional)**: If `--push` was specified, executes `git push -u origin <current_branch>`.

---

## Exit Codes

| Code | Meaning |
| :--- | :--- |
| `0` | Committed (and pushed, with `--push`), or nothing to commit. |
| `2` | Invalid arguments. |
| `4` | Not inside a Git repository. |
| `5` | `--push` requested on a detached `HEAD`. |
| `6` | `git add` failed. |
| `7` | Commit message generation failed (see stderr for the underlying cause). |
| `8` | Generated commit message was empty. |
| `9` | `git commit` failed. |
| `10` | `git push` failed. |
| `11` | `gemini-commit-message` not found. |
| `12` | `git` missing, or the Gemini API key is missing or was rejected. |

---

## Examples

### Stage All Changes and Commit
```bash
ggic
```

### Commit Only Pre-staged Changes
```bash
git add src/core.py
ggic --staged-only
```

### Stage, Commit, and Push Upstream
```bash
ggic --push
```
*(Note: [`ggicp`](ggicp.md) provides a direct shorthand for `ggic --push`).*
