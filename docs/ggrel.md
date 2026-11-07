# `ggrel`

One-shot release command. Generates release notes with [`gemini-release-notes`](gemini-release-notes.md), saves them to a file, and hands that file to [`grel`](grel.md) via `-f`.

---

## Synopsis

```bash
ggrel <version> [grel options]
```

---

## Behavior

1. Runs `gemini-release-notes` from the current Git repository.
2. Saves the output to `${XDG_CACHE_HOME:-~/.cache}/gemini/release-notes/<repo>.md` (overwritten on each run).
3. Runs `grel -f <notes file> <version> [grel options]`.

All arguments except `-h`/`--help` are passed through to `grel` unchanged. `-f`/`--notes-file` and `--notes` are rejected, since `ggrel` supplies the notes itself; use `grel` directly to release with your own notes.

The notes file stays on disk after the run, so you can edit it and re-run the release with `grel <version> -f <notes file>` without calling the Gemini API again.

---

## Exit Codes

| Code | Meaning |
| :--- | :--- |
| `2` | Unsupported option (`-f`, `--notes-file`, `--notes`). |
| `3` | `gemini-release-notes` failed or produced no output. |
| `10` | `gemini-release-notes` or `grel` not found. |
| `11` | Not inside a Git repository. |
| other | Exit code from `grel`. |

---

## Examples

```bash
ggrel 1.2.0
ggrel 1.2.0 --dry-run
ggrel 1.2.0 --test-cmd "make test" -a dist/app.tar.gz
```
