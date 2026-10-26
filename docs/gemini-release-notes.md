# `gemini-release-notes`

Generates structured, factual GitHub-flavored Markdown release notes by analyzing commits and diffstats between the previous release tag and current `HEAD`. Uses fallback model rotation and outputs directly to standard output for direct review or piping into [`ggrel`](ggrel.md).

---

## Synopsis

```bash
gemini-release-notes [options]
```

---

## Options

| Flag | Description |
| :--- | :--- |
| `-h`, `--help` | Displays usage instructions and syntax. |

---

## Behavior & Architecture

1. **Automatic Tag Discovery & Range**:
   - Locates the most recent annotated or lightweight tag formatted as `v[0-9]*` or `[0-9]*` via `git describe --tags`.
   - Analyzes all commits from that tag to `HEAD` (`<previous_tag>..HEAD`).
   - If no previous tag exists in the repository, reviews all commits up to `HEAD`.
2. **Commit Hyperlinks**:
   - Resolves the repository web URL from `git config --get remote.origin.url` (supporting SSH and HTTPS GitHub remotes).
   - Formats commit hashes into direct GitHub commit hyperlinks: `[\`hash\`](https://github.com/.../commit/<full_hash>)`.
3. **Delegation to `gemini-prompt`**:
   - Delegates prompt generation directly to [`gemini-prompt`](gemini-prompt.md), which seamlessly rotates across models configured in [`gemini-rotate-models`](gemini-rotate-models.md).
   - Automatically handles fallback to older models on HTTP 429 / 503 errors.
4. **Standard Output Stream**:
   - All diagnostic logs, progress messages, and model warnings are routed strictly to `stderr`.
   - Only the generated Markdown release notes are outputted to `stdout`, enabling seamless piping.

---

## Examples

### Output Release Notes to Stdout
```bash
gemini-release-notes
```

### Save Release Notes to a File
```bash
gemini-release-notes > release_notes.md
```

### Pipe Directly into `ggrel`
```bash
gemini-release-notes | ggrel 1.2.0
```
