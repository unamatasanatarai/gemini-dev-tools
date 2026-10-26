# `gemini-key`

Securely manages Google Gemini API credentials in an XDG Base Directory compliant vault (`$XDG_CONFIG_HOME/gemini/credentials`, defaulting to `~/.config/gemini/credentials`).

---

## Synopsis

```bash
gemini-key <command> [arguments...]
```

---

## Commands

### `set [KEY]`
Stores your Gemini API key in the credential vault with strict `0600` file permissions.
- If `KEY` is passed as an argument, it is stored immediately.
- If `KEY` is omitted, the command prompts interactively with terminal echo disabled (`read -s`).
- Can also read keys streamed via standard input (e.g. from secret managers or password vaults).

```bash
# Interactive prompt (recommended for interactive shells)
gemini-key set

# Pipe from secret manager
pass show api/gemini | gemini-key set

# Inline argument
gemini-key set "AIzaSy..."
```

---

### `get`
Prints the raw, unquoted API key directly to standard output. Useful for embedding in subshells or piping to other API clients.

```bash
curl -s -H "x-goog-api-key: $(gemini-key get)" \
  https://generativelanguage.googleapis.com/v1beta/models
```

---

### `status`
Inspects credential storage health, file location, and permission mode. Verifies that the credential directory is `0700` and the file is `0600`.

```bash
gemini-key status
```

Example output:
```text
Credential status:
  Config directory: /Users/citizen/.config/gemini [exists, mode: 700]
  Credential file:  /Users/citizen/.config/gemini/credentials [exists, mode: 600]
  Key status:       Configured (length: 39 characters)
```

---

### `env`
Outputs POSIX shell `export` statements for `GEMINI_API_KEY` and `GOOGLE_API_KEY`. Designed to be evaluated directly by your active shell session.

```bash
eval "$(gemini-key env)"
```

---

### `run [--] <cmd> [args...]`
Executes an arbitrary command with `GEMINI_API_KEY` and `GOOGLE_API_KEY` temporarily populated in the subshell environment without leaking keys into long-lived environment tables or shell history.

```bash
gemini-key run -- python train_model.py
gemini-key run -- curl https://generativelanguage.googleapis.com/v1beta/models
```

---

## Options

| Flag | Description |
| :--- | :--- |
| `-h`, `--help`, `help` | Displays usage instructions and command syntax |

---

## Security & Storage Details

- **Path**: `${XDG_CONFIG_HOME:-$HOME/.config}/gemini/credentials`
- **File Permissions**: Strictly validated and enforced at `0600` (read/write only by file owner).
- **Directory Permissions**: Enforced at `0700` (accessible only by owner).
- **Legacy Migration**: Automatically migrates keys from legacy directory `~/.config/gemini-commit-message/key` if present.
