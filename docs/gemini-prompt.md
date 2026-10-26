# `gemini-prompt`

Direct execution interface for the Google Gemini API. Accepts a prompt string as a command-line argument or via standard input (`stdin`), iterates through your configured model fallback rotation queue upon failures or rate limits, and outputs the model response to `stdout`.

All suite commands requiring Gemini text generation (such as [`gemini-commit-message`](gemini-commit-message.md) and [`gemini-release-notes`](gemini-release-notes.md)) delegate their API calling and rotation handling directly to `gemini-prompt`.

---

## Synopsis

```bash
gemini-prompt [options] <prompt>
echo "<prompt>" | gemini-prompt [options]
```

---

## Options

| Flag | Description |
| :--- | :--- |
| `--system <instruction>` | System instruction to steer model context and persona. |
| `-h`, `--help` | Displays usage instructions and syntax. |

---

## Behavior & Fallback Rotation

1. **Prompt Resolution**:
   - Accepts prompt text as positional arguments: `gemini-prompt "Hello Gemini"`.
   - If no prompt argument is provided or `-` is passed, reads prompt text from `stdin`: `cat file.txt | gemini-prompt`.
2. **Model Fallback Rotation**:
   - Reads the ordered model list from `~/.config/gemini/rotation` (configured via [`gemini-rotate-models`](gemini-rotate-models.md)).
   - Displays each model being attempted to `stderr` in real time before dispatching the request.
   - If a model returns HTTP `429` (rate limit), `503`, or fails, it logs a diagnostic warning to `stderr` and seamlessly advances to the next newest model in the rotation queue.
3. **Response Cleaning**:
   - Trims extraneous leading/trailing whitespace.
   - Automatically strips outer Markdown code block fences (```` ``` ````) if returned by the model.
   - Outputs the response strictly to `stdout`, keeping `stderr` reserved for progress logs.

---

## Authentication

Resolves your API key through the following precedence hierarchy:
1. `GEMINI_API_KEY` environment variable
2. `GOOGLE_API_KEY` environment variable
3. Stored vault credentials at `${XDG_CONFIG_HOME:-$HOME/.config}/gemini/credentials` (managed via [`gemini-key`](gemini-key.md))

---

## Examples

### Direct Prompt Argument
```bash
gemini-prompt "Explain the difference between rebase and merge in Git"
```

### Prompt via Standard Input (Piped)
```bash
git diff | gemini-prompt --system "Summarize the changes in this diff"
```

### Using System Instructions
```bash
gemini-prompt --system "You are a concise code reviewer." "Review this function: function add(a, b) { return a + b; }"
```
