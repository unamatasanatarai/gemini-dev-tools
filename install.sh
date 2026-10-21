#!/usr/bin/env bash
set -euo pipefail

install_dir="${XDG_BIN_HOME:-${HOME}/.local/bin}"
base_url="https://raw.githubusercontent.com/unamatasanatarai/gemini-generate-commit-message/master"

files=("ggic" "ggicp" "gemini-generate-commit-message" "gemini-list-models")

if ! command -v curl >/dev/null 2>&1; then
    printf '%s\n' 'curl is required' >&2
    exit 1
fi

mkdir -p "$install_dir" || {
    printf '%s\n' 'failed to create install directory' >&2
    exit 1
}

config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/gemini-commit-message"
mkdir -p "$config_dir" || {
    printf '%s\n' 'failed to create config directory' >&2
    exit 1
}
chmod 700 "$config_dir"

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gemini-install.XXXXXX")"
trap 'rm -rf "${tmp_dir}"' EXIT INT TERM HUP
chmod 700 "${tmp_dir}"

for file in "${files[@]}"; do
    target="${install_dir}/${file}"
    script_url="${base_url}/${file}"
    tmp_file="${tmp_dir}/${file}"

    printf 'installing %s...\n' "$file"

    curl \
        --silent \
        --show-error \
        --fail \
        --location \
        --connect-timeout 10 \
        --max-time 30 \
        --output "$tmp_file" \
        "$script_url"

    if [[ ! -s "$tmp_file" ]]; then
        printf '%s\n' "downloaded file ${file} is empty" >&2
        exit 1
    fi

    chmod 755 "$tmp_file"
    mv "$tmp_file" "$target"
done

printf '\ninstalled to: %s\n' "$install_dir"

case ":$PATH:" in
*":${install_dir}:"*) ;;
*)
    printf '\n%s\n\n' 'add this to your shell profile:'
    printf '%s\n' "export PATH=\"${install_dir}:\$PATH\""
    ;;
esac

printf '\n%s\n' 'usage:'
printf '%s\n' '  ggic'
printf '%s\n' '  ggicp'
printf '%s\n' '  gemini-generate-commit-message'
printf '%s\n' '  gemini-list-models'

printf '\n%s\n' 'configuration:'
printf '  please paste your gemini api key into:\n'
printf '    %s\n' "${config_dir}/key"
printf '  and ensure secure permissions:\n'
printf '    chmod 600 %s\n' "${config_dir}/key"
