# gemini-dev-tools

![Language](https://img.shields.io/badge/language-bash-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Dependencies](https://img.shields.io/badge/dependencies-git%20%7C%20curl%20%7C%20jq-orange)
![Interface](https://img.shields.io/badge/interface-CLI-lightgrey)
![Platform](https://img.shields.io/badge/platform-POSIX-brightgreen)
![API](https://img.shields.io/badge/API-Gemini-red)

A cohesive collection of lightweight, POSIX-compliant Bash utilities powered by the Google Gemini API. The suite provides secure API key management, dynamic model listing and fallback rotation (strictly ordered newest to oldest), automated Git commit message generation with Conventional Commits, and automated Git staging/push workflows.

---

## Features

- **Cohesive XDG Standard**: All tools unify configuration and credentials under `${XDG_CONFIG_HOME:-~/.config}/gemini/`.
- **Credential Vault (`gemini-key`)**: Safely store, inspect, verify, and export your Gemini API key with strict `0600` file permissions.
- **Ordered Fallback Rotation (`gemini-rotate-models`)**: Interactively choose which models to rotate through for resilience against rate limits or outages, automatically enforced from **newest to oldest**.
- **Conventional Commits Generation**: Analyzes staged diffs, filters noisy dependency lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`), and crafts structured commit messages.
- **Automated Git Workflows (`ggic` & `ggicp`)**: Stages working tree changes, executes the model rotation sequence with automatic fallback on failure, and creates commits (and pushes to remote with `ggicp`).
- **Interactive Model Selection (`gemini-pick-model`)**: Easily pick and persist your primary preferred model using `fzf` or clean terminal menus.
- **Intelligent Release Automation (`grel` / `git release`)**: Generates structured, high-quality release notes from Git commit logs using Gemini model rotation, runs pre-release tests/builds, and automates Git tags and GitHub releases.

---

## Tech Stack

- **Core Scripting**: Bash
- **Data Querying & Parsing**: `curl`, `jq`
- **Version Control**: Git
- **API Integration**: Google Gemini API (`v1beta` endpoint)
- **Interactive Menus**: `fzf` (optional, with native CLI fallbacks)

---

## Project Structure

```text
gemini-common.sh                 Shared library for XDG path resolution, key handling, and model sorting.
gemini-key                       CLI vault to store, inspect, and supply API keys in ~/.config/gemini/credentials.
gemini-rotate-models             Interactive selector to manage model rotation lists ordered newest to oldest.
gemini-pick-model                Interactive utility to pick and save primary default model.
gemini-list-models               Queries and filters models from the Gemini API.
gemini-commit-message            Core commit message generator analyzing Git diffs.
ggic                             Automated workflow: stage all, fallback-rotate models, and commit.
ggicp                            Automated workflow: stage all, fallback-rotate models, commit, and push.
grel                             Automated release workflow with Gemini release notes, git tags, and GitHub releases.
install.sh                       Download and installation script to place utilities into ~/.local/bin.
LICENSE                          MIT License declaration.
```

---

## Installation

### Standard Installation

Execute the installation script using `curl`:

```bash
curl -sSL https://raw.githubusercontent.com/unamatasanatarai/gemini-dev-tools/master/install.sh | bash
```

This installs the utilities into `$XDG_BIN_HOME` or `$HOME/.local/bin` and initializes `~/.config/gemini/`.

### Shell PATH Configuration

Ensure your user bin directory is in your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## Configuration & Credentials

All tools respect the XDG Base Directory Specification:

| File | Purpose | Permissions |
| :--- | :--- | :--- |
| `~/.config/gemini/credentials` | Stored Gemini API key | `0600` (user only) |
| `~/.config/gemini/model` | Default primary model | `0644` |
| `~/.config/gemini/rotation` | Ordered fallback models (newest -> oldest) | `0644` |

### 1. Configure API Key

Use `gemini-key` to securely store your API key:

```bash
gemini-key set
```

Or pass via pipe:

```bash
echo "$MY_KEY" | gemini-key set
```

Check the health and permissions of your stored credentials anytime:

```bash
gemini-key status
```

### 2. Configure Model Rotation (Newest to Oldest)

To choose which models you want `ggic` to rotate through on rate-limit or API failures:

```bash
gemini-rotate-models
```

- Launches an interactive `fzf` multi-selector (or numbered CLI menu).
- Press `TAB` to toggle models; press `Enter` to confirm.
- Models are **automatically saved strictly from newest to oldest** in `~/.config/gemini/rotation`.

Display current rotation order:

```bash
gemini-rotate-models --show
```

Reset to curated defaults:

```bash
gemini-rotate-models --reset
```

### 3. Set Primary Default Model

To change the primary model used for single-run commands:

```bash
gemini-pick-model
```

---

## Usage

### Automated Stage, Rotate, and Commit (`ggic`)

Stages working directory changes, runs the rotation fallback sequence if a model is unavailable or rate-limited, and commits:

```bash
ggic
```

Options:
- `--staged-only`: Only commit changes already in the Git staging index.
- `--model <name>`: Override and try a specific model first before falling back to rotation.
- `--push`: Push to upstream branch after committing.

### Automated Stage, Commit, and Push (`ggicp`)

Shortcut that stages all changes, generates the commit message with fallback rotation, commits, and pushes to origin:

```bash
ggicp
```

### Direct Message Output (`gemini-commit-message`)

Prints the generated Conventional Commit message directly to stdout without committing:

```bash
gemini-commit-message
```

### List Models (`gemini-list-models`)

List models available to your API key:

```bash
# List only text/chat generation models, sorted newest to oldest:
gemini-list-models --generate-only --newest
```

### Intelligent Release Management (`grel` / `git release`)

Generates structured GitHub-flavored Markdown release notes from your commit history using Gemini model fallback rotation, updates version files, executes tests/builds, creates annotated git tags, and publishes GitHub releases:

```bash
# Preview release notes without making changes
grel --dry-run

# Automatically bump patch version (e.g. 1.0.0 -> 1.0.1)
grel --patch

# Or bump minor / major version
grel --minor
grel --major

# Specify target version explicitly
grel 1.2.0

# Print only the generated markdown release notes
grel --notes-only
```

---

## License

This project is licensed under the terms of the [MIT License](LICENSE).
