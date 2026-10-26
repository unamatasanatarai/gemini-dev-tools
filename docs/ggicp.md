# `ggicp`

Convenience wrapper that runs [`ggic --push`](ggic.md). Automatically stages changes, generates a commit message using fallback model rotation, commits, and pushes the current branch to `origin`.

---

## Synopsis

```bash
ggicp [options]
```

---

## Options

All options passed to `ggicp` are forwarded directly to [`ggic`](ggic.md):

| Flag | Description |
| :--- | :--- |
| `--staged-only` | Commits only changes already staged in Git index instead of running `git add --all`. |
| `-h`, `--help` | Displays usage instructions. |

---

## Behavior

- **Auto-Staging**: Adds all untracked and modified files (`git add --all`) unless `--staged-only` is provided.
- **Detached HEAD Guard**: Checks `git symbolic-ref --quiet --short HEAD`. If the repository is on a detached HEAD, it aborts before making changes with an error to prevent dangling commits.
- **Push Upstream**: Upon accepting or editing the generated message, commits and immediately pushes to `origin <current_branch>`.

---

## Examples

### Stage, Commit, and Push in One Step
```bash
ggicp
```

### Only Push Currently Staged Files
```bash
git add docs/
ggicp --staged-only
```
