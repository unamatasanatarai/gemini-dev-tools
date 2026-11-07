#!/usr/bin/env bash

# Release configuration for gemini-dev-tools

APP_NAME="gemini-dev-tools"

# Pre-release tests: syntax check plus runtime smoke tests (also under macOS /bin/bash 3.2 when present)
TEST_CMD='bash tests/smoke.sh'

# Build command: archive the committed suite scripts, installer, and documentation (never the working tree)
BUILD_CMD='git archive --format=tar.gz -o "gemini-dev-tools-${target_version}.tar.gz" HEAD -- "gemini-*" "gg*" install.sh LICENSE README.md'

# Assets to attach to the GitHub Release
RELEASE_ASSETS=(
    'gemini-dev-tools-${target_version}.tar.gz'
    "install.sh"
)
