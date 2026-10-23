#!/usr/bin/env bash

install_dir="${XDG_BIN_HOME:-${HOME:-}/.local/bin}"
config_dir="${XDG_CONFIG_HOME:-${HOME:-}/.config}/gemini"
base_url="https://raw.githubusercontent.com/unamatasanatarai/gemini-dev-tools/master"

files=(
    "gemini-common.sh"
    "gemini-key"
    "gemini-list-models"
    "gemini-pick-model"
    "gemini-rotate-models"
    "gemini-commit-message"
    "ggic"
    "ggicp"
    "grel"
)

if ! command -v curl >/dev/null 2>&1; then
    printf 'Error: curl is required\n' >&2
    exit 1
fi

if [[ ! -d "${install_dir}" ]]; then
    mkdir -p "${install_dir}"
    if [[ $? -ne 0 ]]; then
        printf 'Error: failed to create install directory: %s\n' "${install_dir}" >&2
        exit 1
    fi
fi

if [[ ! -d "${config_dir}" ]]; then
    mkdir -p "${config_dir}"
    if [[ $? -ne 0 ]]; then
        printf 'Error: failed to create config directory: %s\n' "${config_dir}" >&2
        exit 1
    fi
fi

chmod 700 "${config_dir}"
if [[ $? -ne 0 ]]; then
    printf 'Error: failed to set permissions on config directory: %s\n' "${config_dir}" >&2
    exit 1
fi

tmp_dir="${install_dir}/.gemini-install-$$"
if [[ -d "${tmp_dir}" ]]; then
    rm -rf "${tmp_dir}"
fi

mkdir -m 700 "${tmp_dir}"
if [[ $? -ne 0 ]]; then
    printf 'Error: failed to create temporary staging directory: %s\n' "${tmp_dir}" >&2
    exit 1
fi

trap 'rm -rf "${tmp_dir}"' EXIT INT TERM HUP

for file in "${files[@]}"; do
    printf 'installing %s...\n' "${file}"
    curl \
        --silent \
        --show-error \
        --fail \
        --location \
        --connect-timeout 10 \
        --max-time 30 \
        --output "${tmp_dir}/${file}" \
        "${base_url}/${file}"
    if [[ $? -ne 0 || ! -s "${tmp_dir}/${file}" ]]; then
        printf 'Error: failed to download %s\n' "${file}" >&2
        exit 1
    fi
done

chmod 755 "${tmp_dir}"/*
if [[ $? -ne 0 ]]; then
    printf 'Error: failed to set permissions on downloaded files\n' >&2
    exit 1
fi

mv -f "${tmp_dir}"/* "${install_dir}/"
if [[ $? -ne 0 ]]; then
    printf 'Error: failed to install files into %s\n' "${install_dir}" >&2
    exit 1
fi

rm -rf "${tmp_dir}"
trap - EXIT INT TERM HUP

for file in "${files[@]}"; do
    if [[ ! -f "${install_dir}/${file}" ]]; then
        printf 'Error: installed file missing: %s\n' "${file}" >&2
        exit 1
    fi
done

printf '\ninstalled to: %s\n' "${install_dir}"

if [[ ":${PATH:-}:" != *":${install_dir}:"* ]]; then
    printf '\nadd this to your shell profile:\n'
    printf 'export PATH="%s:$PATH"\n' "${install_dir}"
fi

printf '\nsuite utilities:\n'
printf '  gemini-key             - Manage Gemini API key credentials\n'
printf '  gemini-rotate-models   - Select & order rotation fallback models (newest to oldest)\n'
printf '  gemini-pick-model      - Set default primary model\n'
printf '  gemini-list-models     - List available models from API\n'
printf '  gemini-commit-message  - Generate commit message from diff\n'
printf '  ggic                   - Auto-stage, fallback-rotate models, and commit\n'
printf '  ggicp                  - Auto-stage, fallback-rotate models, commit, and push\n'
printf '  grel                   - Automated release workflow with Gemini release notes (also git release)\n'

printf '\nquick start:\n'
printf '  1. Store your API key:\n'
printf '     gemini-key set\n'
printf '  2. Configure model rotation (optional):\n'
printf '     gemini-rotate-models\n'
printf '  3. Generate and commit:\n'
printf '     ggic\n'
