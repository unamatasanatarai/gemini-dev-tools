# `gemini-list-models`

Queries the Google Gemini REST API (`https://generativelanguage.googleapis.com/v1beta/models`) using your stored API key and outputs all available generation-capable models, sorted chronologically from newest release to oldest release.

---

## Synopsis

```bash
gemini-list-models
```

---

## Options

| Flag | Description |
| :--- | :--- |
| `-h`, `--help` | Displays usage instructions. |

---

## Authentication

Resolves your API key through the following precedence hierarchy:
1. `GEMINI_API_KEY` environment variable
2. `GOOGLE_API_KEY` environment variable
3. Stored vault credentials at `${XDG_CONFIG_HOME:-$HOME/.config}/gemini/credentials` (managed via [`gemini-key`](gemini-key.md))

---

## Examples

### List Generation Models (Sorted Newest to Oldest)
```bash
gemini-list-models
```

### Pipe into Selection Tools
```bash
gemini-list-models | fzf
```
