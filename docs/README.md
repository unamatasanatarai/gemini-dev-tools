# Documentation Index

Welcome to the detailed documentation for **gemini-dev-tools**, a modular suite of Pure Bash command-line developer automation utilities powered by the Google Gemini REST API.

---

## Command Reference

| Command | Category | Description | Documentation |
| :--- | :--- | :--- | :--- |
| [`gemini-key`](gemini-key.md) | Credentials | Secure XDG-compliant storage and environment injection for API keys | [gemini-key.md](gemini-key.md) |
| [`gemini-list-models`](gemini-list-models.md) | Models | Queries and filters generation-capable models from the Gemini API | [gemini-list-models.md](gemini-list-models.md) |
| [`gemini-rotate-models`](gemini-rotate-models.md) | Models | Configures and inspects ordered fallback rotation lists (newest to oldest) | [gemini-rotate-models.md](gemini-rotate-models.md) |
| [`gemini-prompt`](gemini-prompt.md) | Generation | Core prompt execution command using ordered model fallback rotation | [gemini-prompt.md](gemini-prompt.md) |
| [`gemini-commit-message`](gemini-commit-message.md) | Git & Commits | Analyzes staged and unstaged Git diffs to generate Conventional Commits | [gemini-commit-message.md](gemini-commit-message.md) |
| [`ggic`](ggic.md) | Git & Commits | Automated Git workflow: stage changes, generate commit message, review, and commit | [ggic.md](ggic.md) |
| [`ggicp`](ggicp.md) | Git & Commits | Shortcut workflow: stage changes, commit with fallback rotation, and push upstream | [ggicp.md](ggicp.md) |
| [`gemini-release-notes`](gemini-release-notes.md) | Releases | Generates categorized Markdown release notes between previous tag and HEAD | [gemini-release-notes.md](gemini-release-notes.md) |
| [`ggrel`](ggrel.md) | Releases | Automated release workflow: runs tests/builds, bumps version, tags, pushes, and publishes to GitHub | [ggrel.md](ggrel.md) |

---

## Core Architecture & Workflow Integration

### 1. Model Rotation & Error Fallback
All utilities that generate text from the Gemini API delegate execution to [`gemini-prompt`](gemini-prompt.md), which implements automatic model fallback rotation:
- On HTTP `429` (rate limit), `503` (service unavailable), or empty responses, the script automatically advances to the next newest generation-capable model.
- Model ordering is user-managed via [`gemini-rotate-models`](gemini-rotate-models.md).

### 2. Composable Release Pipeline
Releases are designed as a two-stage UNIX pipeline:
```bash
gemini-release-notes | ggrel 1.2.0
```
- **Stage 1 ([`gemini-release-notes`](gemini-release-notes.md))**: Focuses strictly on synthesizing commits and file changes into GitHub-flavored Markdown.
- **Stage 2 ([`ggrel`](ggrel.md))**: Focuses on verification, dry runs, interactive confirmation, running tests/builds, tagging, git pushes, and GitHub release publication.
