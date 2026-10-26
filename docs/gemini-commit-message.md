# `gemini-commit-message`

Core commit message generator. Inspects staged Git diffs (or unstaged diffs if no files are staged, respecting `.gitignore`), and sends the diff to the Gemini API to produce Conventional Commit messages formatted with concise subjects and technical bullet points.

---

## Synopsis

```bash
gemini-commit-message
```

---

## Options

| Flag | Description |
| :--- | :--- |
| `-h`, `--help` | Displays usage instructions. |

---

## Behavior & Filtering

1. **Git State Inspection**:
   - Inspects `git diff --cached` for staged changes.
   - If nothing is staged, inspects `git diff` for unstaged changes (respecting `.gitignore`).
   - If no changes are detected, exits with status `3`.
2. **Commit Formatting**:
   - Adheres strictly to the Conventional Commits specification (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, etc.).
   - Produces a concise imperative subject line under 72 characters.
   - Appends detailed bullet points explaining user-facing or technical changes.
   - Strips Markdown code blocks (` ``` `) automatically so only raw commit message text is outputted to stdout.
3. **Prompt Execution via `gemini-prompt`**:
   - Delegates the formatted prompt and system instructions to [`gemini-prompt`](gemini-prompt.md), which handles fallback rotation across models configured in [`gemini-rotate-models`](gemini-rotate-models.md).

---

## Exit Codes

| Code | Meaning |
| :--- | :--- |
| `0` | Commit message generated successfully |
| `2` | Invalid CLI arguments |
| `3` | Working tree is clean (no staged or unstaged changes) |
| `4` | Not inside a Git repository |
| `10` | Missing required dependencies (`git`, `curl`, or `jq`) |
| `11` | Gemini API key is missing or invalid |
| `19` | All fallback models failed to generate a commit message |

---

## Examples

### Output Commit Message to Stdout
```bash
gemini-commit-message
```

### Save Message Directly to a File
```bash
gemini-commit-message > /tmp/commit-msg.txt
```

### Create a Git Commit with Generated Message
```bash
git commit -m "$(gemini-commit-message)"
```
