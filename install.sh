#!/usr/bin/env bash

install_dir="${XDG_BIN_HOME:-${HOME:-}/.local/bin}"
config_dir="${XDG_CONFIG_HOME:-${HOME:-}/.config}/gemini"
repo="unamatasanatarai/gemini-dev-tools"

files=(
    "gemini-common.sh"
    "gemini-key"
    "gemini-list-models"
    "gemini-rotate-models"
    "gemini-prompt"
    "gemini-commit-message"
    "ggic"
    "ggicp"
    "gemini-release-notes"
    "ggrel"
)

if ! command -v curl >/dev/null 2>&1; then
    printf 'Error: curl is required\n' >&2
    exit 1
fi

latest_url="$(curl -sS -w '%{url_effective}' -o /dev/null -L --connect-timeout 10 --max-time 15 "https://github.com/${repo}/releases/latest" 2>/dev/null)"
release_tag="master"
[[ "${latest_url}" =~ /releases/tag/([^/]+)$ ]] && release_tag="${BASH_REMATCH[1]}"
base_url="https://raw.githubusercontent.com/${repo}/${release_tag}"

if [[ ! -d "${install_dir}" ]]; then
    mkdir -p "${install_dir}"
    if [[ $? -ne 0 ]]; then
        printf 'Error: failed to create install directory: %s\n' "${install_dir}" >&2
        exit 2
    fi
fi

if [[ ! -d "${config_dir}" ]]; then
    mkdir -m 0700 -p "${config_dir}"
    if [[ $? -ne 0 ]]; then
        printf 'Error: failed to create config directory: %s\n' "${config_dir}" >&2
        exit 2
    fi
fi

tmp_dir="${install_dir}/.gemini-install-$$"
mkdir -m 0700 "${tmp_dir}"
if [[ $? -ne 0 ]]; then
    printf 'Error: failed to create temporary staging directory: %s\n' "${tmp_dir}" >&2
    exit 2
fi
trap 'rm -rf "${tmp_dir}"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

curl_args=()
staged=()
for file in "${files[@]}"; do
    printf 'installing %s...\n' "${file}"
    curl_args+=(--output "${tmp_dir}/${file}" "${base_url}/${file}")
    staged+=("${tmp_dir}/${file}")
done

curl --silent --show-error --fail --fail-early --location --connect-timeout 10 --max-time 120 "${curl_args[@]}"
if [[ $? -ne 0 ]]; then
    printf 'Error: failed to download release files from %s\n' "${base_url}" >&2
    exit 3
fi

for file in "${staged[@]}"; do
    if [[ ! -s "${file}" ]]; then
        printf 'Error: failed to download %s\n' "${file##*/}" >&2
        exit 3
    fi
done

chmod 0755 "${staged[@]}"
if [[ $? -ne 0 ]]; then
    printf 'Error: failed to set permissions on downloaded files\n' >&2
    exit 4
fi

mv -f "${staged[@]}" "${install_dir}/"
if [[ $? -ne 0 ]]; then
    printf 'Error: failed to install files into %s\n' "${install_dir}" >&2
    exit 4
fi

for file in "${files[@]}"; do
    if [[ ! -f "${install_dir}/${file}" ]]; then
        printf 'Error: installed file missing: %s\n' "${file}" >&2
        exit 4
    fi
done

printf '\ninstalled (%s) to: %s\n' "${release_tag}" "${install_dir}"

if [[ ":${PATH:-}:" != *":${install_dir}:"* ]]; then
    printf '\nadd this to your shell profile:\nexport PATH="%s:$PATH"\n' "${install_dir}"
fi

printf '%s\n' \
    '' \
    'suite utilities:' \
    '  gemini-key             - Manage Gemini API key credentials' \
    '  gemini-rotate-models   - Select & order rotation fallback models (newest to oldest)' \
    '  gemini-list-models     - List available models from API' \
    '  gemini-prompt          - Send prompt to Gemini API with fallback rotation' \
    '  gemini-commit-message  - Generate commit message from diff' \
    '  ggic                   - Auto-stage, fallback-rotate models, and commit' \
    '  ggicp                  - Auto-stage, fallback-rotate models, commit, and push' \
    '  gemini-release-notes   - Generate categorized Markdown release notes with Gemini' \
    '  ggrel                  - Automated release workflow: test, bump version, tag, and publish' \
    '' \
    'quick start:' \
    '  1. Store your API key:' \
    '     gemini-key set' \
    '  2. Configure model rotation (optional):' \
    '     gemini-rotate-models' \
    '  3. Generate and commit:' \
    '     ggic'
