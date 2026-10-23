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

- **Automated Conventional Commits**: Inspects staged and unstaged Git diffs, excludes lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`), and generates standards-compliant commit messages with concise subjects and technical bullet points.
- **Ordered Model Fallback Rotation**: Automatically iterates through a user-configurable rotation list sorted from newest to oldest model versions upon HTTP 429 rate limits, service errors, or empty completions.
- **XDG Credential Vault (`gemini-key`)**: Securely stores API keys under strict `0600` permissions with status validation, non-echoing interactive prompts, and runtime environment variable exports.
- **Full Release Automation (`grel` / `git release`)**: Synthesizes commit logs and diffstats into categorized GitHub-flavored Markdown release notes, executes pre-release test and build hooks, bumps SemVer tags, and publishes releases via the GitHub CLI.
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

## Project Structure

```text
gemini-common.sh         Shared library for XDG resolution, credential retrieval, and native model sorting
gemini-key               Credential vault to set, inspect, export, and run commands with API keys
gemini-list-models       Queries and filters generation-capable Gemini models from the API
gemini-pick-model        Interactive menu to select and promote a primary default model
gemini-rotate-models     Interactive selector and CLI manager for fallback rotation order
gemini-commit-message    Core generator analyzing Git diffs to output Conventional Commit messages
ggic                     Automated Git workflow: stage changes, generate commit message, and commit
ggicp                    Wrapper workflow: stage changes, commit with model rotation, and push upstream
grel                     Automated release pipeline: generate release notes, tag, test, build, and publish
install.sh               Installer pulling release assets dynamically into ~/.local/bin
LICENSE                  MIT License declaration
README.md                Project documentation
```

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
| `GEMINI_SUMMARY_MODEL` | Secondary model override |
| `GIT_SUMMARY_MODEL` | Fallback model override |
| `XDG_CONFIG_HOME` | Configuration root directory (defaults to `$HOME/.config`) |
| `XDG_BIN_HOME` | Binary installation directory (defaults to `$HOME/.local/bin`) |
| `XDG_CACHE_HOME` | Cache root directory (defaults to `$HOME/.cache`) |

### Repository Release Hooks

When running `grel`, repository-specific configuration can be defined in `.git-release.sh` or `.release.sh` at the repository root:

```bash
APP_NAME="my-app"
TEST_CMD="npm test"
BUILD_CMD="npm run build"
VERSION_FILE="package.json"
GEMINI_MODEL="gemini-2.5-flash"
RELEASE_ASSETS=("dist/app.tar.gz")
```

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

### 3. Select Primary Default Model (`gemini-pick-model`)

Interactively promote a model to the top of the rotation order:

```bash
gemini-pick-model
```

### 4. Query Available Models (`gemini-list-models`)

Query API models filtered by generation capabilities and ordered chronologically:

```bash
gemini-list-models --generate-only --newest
```

### 5. Generate Commit Messages (`gemini-commit-message`)

Generate and print a Conventional Commit message to stdout based on the working tree or staging index:

```bash
gemini-commit-message
```

Override the model for a single invocation:

```bash
gemini-commit-message --model gemini-2.5-flash
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

### 7. Release Automation (`grel` / `git release`)

Analyze commits since the last release, generate structured markdown release notes, execute test/build hooks, create an annotated Git tag, and publish to GitHub:

```bash
# Preview release notes and target version without altering state
grel --dry-run

# Automatically compute SemVer bumps
grel --patch
grel --minor
grel --major

# Specify an explicit version target
grel 1.2.0

# Output release notes only to stdout
grel --notes-only

# Attach release assets to GitHub release
grel --patch -a dist/bundle.tar.gz
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
