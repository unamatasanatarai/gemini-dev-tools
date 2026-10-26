#!/usr/bin/env bash

# Release configuration for gemini-dev-tools

APP_NAME="gemini-dev-tools"

# Pre-release tests: syntax check all shell scripts
TEST_CMD='for f in gemini-* gg* install.sh; do [[ -f "$f" ]] && bash -n "$f"; done'

# Build command: bundle suite scripts, installer, and documentation into release tarball
BUILD_CMD='tar -czf "gemini-dev-tools-${target_version}.tar.gz" gemini-* gg* install.sh LICENSE README.md'

# Assets to attach to the GitHub Release
RELEASE_ASSETS=(
    'gemini-dev-tools-${target_version}.tar.gz'
    "install.sh"
)
