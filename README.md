# gemini-dev-tools

![Language](https://img.shields.io/badge/language-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue)
![Specification](https://img.shields.io/badge/standard-XDG-lightgrey)
![Commits](https://img.shields.io/badge/commits-Conventional-FE5196?logo=conventionalcommits&logoColor=white)
![Platform](https://img.shields.io/badge/platform-POSIX-000000)
![API](https://img.shields.io/badge/API-Google%20Gemini-4285F4?logo=google&logoColor=white)
![Interface](https://img.shields.io/badge/interface-CLI-24292e)

A modular suite of high-performance Pure Bash CLI utilities built on the Google Gemini API for developer automation. It streamlines Git workflows through automated Conventional Commit generation, model fallback rotation, credential storage, and automated release publishing. The tools eliminate repetitive workflow overhead while remaining lightweight, dependency-minimal, and compliant with XDG base directory specifications.

---

## Features

- **Automated Conventional Commits**: Inspects staged and unstaged Git diffs (respecting `.gitignore`), and generates standards-compliant commit messages with concise subjects and technical bullet points.
- **Ordered Model Fallback Rotation**: Automatically iterates through a user-configurable rotation list sorted from newest to oldest model versions upon HTTP 429 rate limits, service errors, or empty completions.
- **Intelligent Release Notes (`gemini-release-notes`)**: Synthesizes commit logs and diffstats into categorized GitHub-flavored Markdown release notes with automatic commit hyperlinking and fallback model rotation.
- **Full Release Automation (`ggrel`)**: Executes pre-release test and build hooks, bumps SemVer tags, updates version files, and publishes releases via the GitHub CLI using provided or generated release notes.
- **Interactive Model Selection**: Inspects Gemini API capabilities, filters generation-capable models, and provides interactive model picking and rotation management using optional `fzf` integration with fallback terminal menus.
- **Pure Bash Architecture**: Implemented with flat execution flow, zero subshells in core paths, native array sorting, and elimination of unnecessary external binary forks (`awk`, `sed`, `grep`, `tr`, `mktemp`).

---

## Tech Stack

- **Runtime & Scripting**: Bash (POSIX-compliant environment targeting `#!/usr/bin/env bash`)
- **Version Control**: Git
- **External Dependencies**: `curl` (HTTP requests), `jq` (JSON payload handling), `gh` (optional, GitHub releases)
- **Optional CLI Enhancements**: `fzf` (interactive fuzzy selection)
- **API Target**: Google Gemini REST API (`v1beta` endpoint)
- **Standards**: XDG Base Directory Specification, Conventional Commits specification

---

### Command Documentation

Detailed usage guides, flag definitions, and workflow examples for each utility are available in the [`docs/`](docs/README.md) directory:

- [`gemini-key`](docs/gemini-key.md) - Credential management and environment variable injection
- [`gemini-list-models`](docs/gemini-list-models.md) - Model capability filtering and chronological sorting
- [`gemini-rotate-models`](docs/gemini-rotate-models.md) - Model fallback rotation configuration
- [`gemini-prompt`](docs/gemini-prompt.md) - Direct prompt execution with model fallback rotation
- [`gemini-commit-message`](docs/gemini-commit-message.md) - Conventional Commit generation from Git diffs
- [`ggic`](docs/ggic.md) - Interactive stage, generate, review, and commit workflow
- [`ggicp`](docs/ggicp.md) - Commit with model rotation and push upstream
- [`gemini-release-notes`](docs/gemini-release-notes.md) - Categorized Markdown release notes generation
- [`ggrel`](docs/ggrel.md) - Full release automation (tests, builds, tags, pushes, and GitHub release)

---

## Installation

The installation script fetches the latest GitHub release assets and installs the binaries into `$XDG_BIN_HOME` or `$HOME/.local/bin`.

```bash
curl -sSL https://raw.githubusercontent.com/unamatasanatarai/gemini-dev-tools/master/install.sh | bash
```

### Environment Configuration

Ensure `$HOME/.local/bin` (or your configured `$XDG_BIN_HOME`) is present in your shell `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## Configuration

All utilities adhere to the XDG Base Directory Specification.

### File Locations and Permissions

| Path | Purpose | Required Permissions |
| :--- | :--- | :--- |
| `~/.config/gemini/credentials` | Stored Google Gemini API key | `0600` (user read/write only) |
| `~/.config/gemini/rotation` | Ordered fallback models (newest to oldest) | `0644` |
| `~/.cache/gemini/` | Cache directory for runtime artifacts | `0700` |

### Environment Variables

The suite respects the following environment variables, evaluated in precedence order before filesystem lookups:

| Variable | Description |
| :--- | :--- |
| `GEMINI_API_KEY` | Primary Gemini API key |
| `GOOGLE_API_KEY` | Secondary Gemini API key fallback |
| `GEMINI_MODEL` | Explicit primary model override across all utilities |
| `XDG_CONFIG_HOME` | Configuration root directory (defaults to `$HOME/.config`) |
| `XDG_BIN_HOME` | Binary installation directory (defaults to `$HOME/.local/bin`) |
| `XDG_CACHE_HOME` | Cache root directory (defaults to `$HOME/.cache`) |

---

## Usage

### 1. Manage API Credentials (`gemini-key`)

Store an API key securely:

```bash
gemini-key set
```

Pipe an existing key into the credential store:

```bash
printf '%s' "$MY_API_KEY" | gemini-key set
```

Verify storage permissions and credential health:

```bash
gemini-key status
```

Print shell export statements for direct terminal evaluation:

```bash
eval "$(gemini-key env)"
```

Execute an arbitrary command with credentials injected into the subshell environment:

```bash
gemini-key run -- curl -H "x-goog-api-key: $GEMINI_API_KEY" https://generativelanguage.googleapis.com/v1beta/models
```

### 2. Configure Model Fallback Rotation (`gemini-rotate-models`)

Launch interactive model selection (supports `fzf` multi-select with `TAB` toggling):

```bash
gemini-rotate-models
```

Display the active model rotation order:

```bash
gemini-rotate-models --show
```

Reset the rotation list to curated defaults:

```bash
gemini-rotate-models --reset
```

Explicitly define or mutate rotation entries:

```bash
gemini-rotate-models --set gemini-3.8-flash,gemini-3.5-flash-lite,gemini-2.5-flash
gemini-rotate-models --add gemini-2.5-pro
gemini-rotate-models --remove gemini-3.5-flash-lite
```

### 3. Query Available Models (`gemini-list-models`)

Query generation-capable API models ordered chronologically from newest to oldest:

```bash
gemini-list-models
```

### 4. Execute Gemini Prompts (`gemini-prompt`)

Send any prompt to the Gemini API with automatic model fallback rotation:

```bash
gemini-prompt "Explain the difference between rebase and merge in Git"
```

Pass prompts via pipe with system instructions:

```bash
git diff | gemini-prompt --system "Summarize changes concisely"
```

### 5. Generate Commit Messages (`gemini-commit-message`)

Generate and print a Conventional Commit message to stdout based on the working tree or staging index:

```bash
gemini-commit-message
```

### 6. Automated Commit Workflows (`ggic` & `ggicp`)

Stage all changes, generate the commit message using fallback rotation, and create the Git commit:

```bash
ggic
```

Restrict commit generation to already-staged changes:

```bash
ggic --staged-only
```

Stage, commit, and push upstream in a single command:

```bash
ggicp
```

### 7. Release Automation (`gemini-release-notes` & `ggrel`)

The release pipeline is split into two composable commands:

#### Step 1: Generate Release Notes (`gemini-release-notes`)

Analyzes commits between the previous release tag and current `HEAD`, synthesizes changes using Gemini with fallback model rotation, and outputs structured Markdown release notes to stdout:

```bash
# Output release notes for unreleased commits to stdout
gemini-release-notes

# Redirect to a file via shell redirection
gemini-release-notes > release_notes.md
```

#### Step 2: Publish Release (`ggrel`)

Takes release notes generated in Step 1, runs test/build hooks, bumps the version file, creates an annotated Git tag, pushes to origin, and publishes via the GitHub CLI:

```bash
# Pipe directly from gemini-release-notes
gemini-release-notes | ggrel 1.2.0

# Provide pre-generated notes via file or inline argument
ggrel 1.2.0 -f release_notes.md
ggrel 1.2.0 --notes "### Features\n- New capability"

# Preview release actions without altering repository state
gemini-release-notes | ggrel 1.2.0 --dry-run

# Attach release assets
ggrel 1.2.0 -f release_notes.md -a dist/bundle.tar.gz
```

---

## API Documentation

The utilities communicate directly with the Google Gemini REST API (`v1beta` endpoint).

### Endpoints Used

- `GET https://generativelanguage.googleapis.com/v1beta/models`
  Queries available models and capabilities. Authenticated via `x-goog-api-key` header.
- `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
  Executes structured text generation with JSON payloads containing `system_instruction`, `contents`, and `generationConfig` parameters.

---

## License

This project is licensed under the terms of the [MIT License](LICENSE).
