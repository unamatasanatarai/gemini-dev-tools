# `gemini-rotate-models`

Selects and manages the ordered fallback rotation list of Google Gemini models. When utilities encounter HTTP `429` (rate limits), service errors, or empty responses, they fall back through the models defined here from newest to oldest.

---

## Synopsis

```bash
gemini-rotate-models [command|options]
```

---

## Commands & Options

| Command / Option | Description |
| :--- | :--- |
| *(no arguments)* | Launches interactive multi-select model configuration using `fzf` (if installed) or a numbered terminal menu. |
| `-s`, `--show` | Displays the current rotation list in chronological fallback order. |
| `--reset` | Resets the rotation list to the suite's recommended built-in defaults. |
| `--set <m1,m2,...>` | Explicitly overwrites the rotation list using a comma-separated list of model names. Re-orders models from newest to oldest automatically. |
| `--add <model>` | Adds an individual model to the rotation file, preserving chronological ordering. |
| `--remove <model>` | Removes an individual model from the rotation file. |
| `--all` | Includes preview, experimental, and specialized models in the interactive picker. |
| `-h`, `--help` | Displays usage instructions and available commands. |

---

## Configuration File

The configured rotation list resides at:
```text
${XDG_CONFIG_HOME:-$HOME/.config}/gemini/rotation
```
Each non-comment line represents an active model in the fallback queue.

---

## Examples

### Interactive Multi-Selection
```bash
gemini-rotate-models
```

### Display Current Rotation Order
```bash
gemini-rotate-models --show
```
Example output:
```text
Current Gemini model rotation order (newest -> oldest):
Source: /Users/citizen/.config/gemini/rotation
  1. gemini-pro-latest
  2. gemini-flash-latest
  3. gemini-3.8-flash
  4. gemini-2.5-pro
  5. gemini-2.5-flash
```

### Set Explicit Models
```bash
gemini-rotate-models --set gemini-3.8-flash,gemini-2.5-flash,gemini-2.5-flash-lite
```

### Add a Specific Model
```bash
gemini-rotate-models --add gemini-3.8-flash
```

### Reset to Defaults
```bash
gemini-rotate-models --reset
```
