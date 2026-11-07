#!/usr/bin/env bash

GEMINI_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME:-}/.config}/gemini"
GEMINI_CRED_FILE="${GEMINI_CONFIG_DIR}/credentials"
GEMINI_ROTATION_FILE="${GEMINI_CONFIG_DIR}/rotation"
GEMINI_API_URL="https://generativelanguage.googleapis.com/v1beta/models"

GEMINI_DEFAULT_ROTATION=(
    "gemini-pro-latest"
    "gemini-flash-latest"
    "gemini-flash-lite-latest"
    "gemini-4-argon"
    "gemini-3.8-flash"
    "gemini-3.7-flash"
    "gemini-3.6-flash"
    "gemini-3.5-flash"
    "gemini-3.5-flash-lite"
    "gemini-3.1-flash-lite"
    "gemini-2.5-pro"
    "gemini-2.5-flash"
    "gemini-2.5-flash-lite"
)

GEMINI_ROTATION=()
GEMINI_ROTATION_SOURCE=""
if [[ -f "${GEMINI_ROTATION_FILE}" ]]; then
    while IFS= read -r _gc_line || [[ -n "${_gc_line}" ]]; do
        _gc_line="${_gc_line#"${_gc_line%%[![:space:]]*}"}"
        _gc_line="${_gc_line%"${_gc_line##*[![:space:]]}"}"
        [[ -n "${_gc_line}" && "${_gc_line}" != \#* ]] && GEMINI_ROTATION+=("${_gc_line}")
    done <"${GEMINI_ROTATION_FILE}"
fi
if ((${#GEMINI_ROTATION[@]} > 0)); then
    GEMINI_ROTATION_SOURCE="${GEMINI_ROTATION_FILE}"
else
    GEMINI_ROTATION=("${GEMINI_DEFAULT_ROTATION[@]}")
fi

GEMINI_KEY="${GEMINI_API_KEY:-${GOOGLE_API_KEY:-}}"
_gc_legacy_key="${XDG_CONFIG_HOME:-${HOME:-}/.config}/gemini-commit-message/key"
if [[ -z "${GEMINI_KEY}" && -f "${_gc_legacy_key}" && ! -f "${GEMINI_CRED_FILE}" ]]; then
    [[ -d "${GEMINI_CONFIG_DIR}" ]] || mkdir -m 0700 -p "${GEMINI_CONFIG_DIR}" 2>/dev/null
    IFS= read -r _gc_line <"${_gc_legacy_key}"
    printf '%s\n' "${_gc_line}" 2>/dev/null >"${GEMINI_CRED_FILE}" && chmod 0600 "${GEMINI_CRED_FILE}" 2>/dev/null
fi
if [[ -z "${GEMINI_KEY}" && -f "${GEMINI_CRED_FILE}" ]]; then
    IFS= read -r GEMINI_KEY <"${GEMINI_CRED_FILE}"
fi
GEMINI_KEY="${GEMINI_KEY//$'\r'/}"
GEMINI_KEY="${GEMINI_KEY#"${GEMINI_KEY%%[![:space:]]*}"}"
GEMINI_KEY="${GEMINI_KEY%"${GEMINI_KEY##*[![:space:]]}"}"
unset _gc_line _gc_legacy_key

gemini_sort_models() {
    local -n _gs_list="$1"
    local -a _gs_items=() _gs_keys=()
    local -A _gs_seen=()
    local _gs_m="" _gs_key="" _gs_latest=0 _gs_major=0 _gs_minor=0 _gs_tier=0 _gs_j=0 _gs_n=0
    for _gs_m in "${_gs_list[@]}"; do
        _gs_m="${_gs_m#"${_gs_m%%[![:space:]]*}"}"
        _gs_m="${_gs_m%"${_gs_m##*[![:space:]]}"}"
        [[ -z "${_gs_m}" || "${_gs_m}" == \#* || -n "${_gs_seen[${_gs_m}]:-}" ]] && continue
        _gs_seen["${_gs_m}"]=1
        _gs_latest=0
        [[ "${_gs_m}" == *-latest* ]] && _gs_latest=1
        _gs_major=0
        _gs_minor=0
        if [[ "${_gs_m}" =~ ([0-9]+)(\.([0-9]+))? ]]; then
            _gs_major=$((10#${BASH_REMATCH[1]}))
            [[ -n "${BASH_REMATCH[3]}" ]] && _gs_minor=$((10#${BASH_REMATCH[3]}))
        fi
        _gs_tier=0
        case "${_gs_m}" in
        *pro*) _gs_tier=3 ;;
        *flash-lite*) _gs_tier=1 ;;
        *flash*) _gs_tier=2 ;;
        esac
        printf -v _gs_key '%d%05d%05d%d_%s' "${_gs_latest}" "${_gs_major}" "${_gs_minor}" "${_gs_tier}" "${_gs_m}"
        _gs_n=${#_gs_items[@]}
        _gs_j=${_gs_n}
        while ((_gs_j > 0)) && [[ "${_gs_keys[_gs_j - 1]}" < "${_gs_key}" ]]; do
            _gs_keys[_gs_j]="${_gs_keys[_gs_j - 1]}"
            _gs_items[_gs_j]="${_gs_items[_gs_j - 1]}"
            ((_gs_j--))
        done
        _gs_keys[_gs_j]="${_gs_key}"
        _gs_items[_gs_j]="${_gs_m}"
    done
    _gs_list=("${_gs_items[@]}")
}
