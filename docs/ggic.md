# `ggic`

Interactive Git commit workflow automation tool. Stages changes, generates a Conventional Commit message via [`gemini-commit-message`](gemini-commit-message.md), lets you review or edit the message in your preferred `$EDITOR`, and commits.

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
4. **Interactive Review**:
   - Displays the generated commit message.
   - If running in a terminal, prompts you to accept `[y]`, edit in `$EDITOR` `[e]`, regenerate `[r]`, or abort `[n]`.
5. **Commit**: Runs `git commit -F <message_file>`.
6. **Push (Optional)**: If `--push` was specified, executes `git push origin <current_branch>`.

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
