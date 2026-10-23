#!/usr/bin/env bash

GEMINI_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME:-}/.config}/gemini"
GEMINI_CRED_FILE="${GEMINI_CONFIG_DIR}/credentials"
GEMINI_ROTATION_FILE="${GEMINI_CONFIG_DIR}/rotation"
GEMINI_CACHE_DIR="${XDG_CACHE_HOME:-${HOME:-}/.cache}/gemini"

gemini_config_dir() {
    printf '%s\n' "${GEMINI_CONFIG_DIR}"
}

gemini_cred_file() {
    printf '%s\n' "${GEMINI_CRED_FILE}"
}

gemini_rotation_file() {
    printf '%s\n' "${GEMINI_ROTATION_FILE}"
}

gemini_cache_dir() {
    printf '%s\n' "${GEMINI_CACHE_DIR}"
}

gemini_migrate_legacy() {
    local legacy_dir="${XDG_CONFIG_HOME:-${HOME:-}/.config}/gemini-commit-message"
    local legacy_key="${legacy_dir}/key"

    if [[ -d "${legacy_dir}" && -f "${legacy_key}" && ! -f "${GEMINI_CRED_FILE}" ]]; then
        if [[ ! -d "${GEMINI_CONFIG_DIR}" ]]; then
            mkdir -m 0700 -p "${GEMINI_CONFIG_DIR}"
        fi
        chmod 0700 "${GEMINI_CONFIG_DIR}" 2>/dev/null
        cp "${legacy_key}" "${GEMINI_CRED_FILE}" 2>/dev/null
        chmod 0600 "${GEMINI_CRED_FILE}" 2>/dev/null
    fi
}

gemini_get_api_key() {
    local key=""

    if [[ -n "${GEMINI_API_KEY:-}" ]]; then
        key="${GEMINI_API_KEY}"
    elif [[ -n "${GOOGLE_API_KEY:-}" ]]; then
        key="${GOOGLE_API_KEY}"
    else
        gemini_migrate_legacy
        if [[ -f "${GEMINI_CRED_FILE}" ]]; then
            IFS= read -r key <"${GEMINI_CRED_FILE}"
        fi
    fi

    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    key="${key//$'\r'/}"
    key="${key//$'\n'/}"

    if [[ -n "${key}" ]]; then
        printf '%s' "${key}"
        return 0
    fi
    return 1
}

gemini_get_default_rotation() {
    printf '%s\n' \
        "gemini-pro-latest" \
        "gemini-flash-latest" \
        "gemini-flash-lite-latest" \
        "gemini-4-argon" \
        "gemini-3.8-flash" \
        "gemini-3.7-flash" \
        "gemini-3.6-flash" \
        "gemini-3.5-flash" \
        "gemini-3.5-flash-lite" \
        "gemini-3.1-flash-lite" \
        "gemini-2.5-pro" \
        "gemini-2.5-flash" \
        "gemini-2.5-flash-lite"
}

gemini_get_rotation_models() {
    local line=""
    local -a models=()

    if [[ -f "${GEMINI_ROTATION_FILE}" ]]; then
        while IFS= read -r line || [[ -n "${line}" ]]; do
            line="${line#"${line%%[![:space:]]*}"}"
            line="${line%"${line##*[![:space:]]}"}"
            if [[ -n "${line}" && "${line}" != \#* ]]; then
                models+=("${line}")
            fi
        done <"${GEMINI_ROTATION_FILE}"
    fi

    if [[ ${#models[@]} -gt 0 ]]; then
        printf '%s\n' "${models[@]}"
    else
        gemini_get_default_rotation
    fi
}

gemini_get_primary_model() {
    local cli_model="${1:-}"
    local top_model=""
    local line=""

    if [[ -n "${cli_model}" ]]; then
        printf '%s\n' "${cli_model}"
        return 0
    fi

    if [[ -n "${GEMINI_MODEL:-}" ]]; then
        printf '%s\n' "${GEMINI_MODEL}"
        return 0
    fi

    if [[ -n "${GEMINI_SUMMARY_MODEL:-}" ]]; then
        printf '%s\n' "${GEMINI_SUMMARY_MODEL}"
        return 0
    fi

    if [[ -n "${GIT_SUMMARY_MODEL:-}" ]]; then
        printf '%s\n' "${GIT_SUMMARY_MODEL}"
        return 0
    fi

    if [[ -f "${GEMINI_ROTATION_FILE}" ]]; then
        while IFS= read -r line || [[ -n "${line}" ]]; do
            line="${line#"${line%%[![:space:]]*}"}"
            line="${line%"${line##*[![:space:]]}"}"
            if [[ -n "${line}" && "${line}" != \#* ]]; then
                top_model="${line}"
                break
            fi
        done <"${GEMINI_ROTATION_FILE}"
    fi

    if [[ -n "${top_model}" ]]; then
        printf '%s\n' "${top_model}"
        return 0
    fi

    printf '%s\n' "gemini-pro-latest"
}

gemini_sort_models_newest_to_oldest() {
    local -a items=()
    local -a keys=()
    local line=""
    local is_latest=0
    local major=0
    local minor=0
    local tier=0
    local key=""

    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        if [[ -z "${line}" || "${line}" == \#* ]]; then
            continue
        fi

        items+=("${line}")

        is_latest=0
        if [[ "${line}" == *-latest* ]]; then
            is_latest=1
        fi

        major=0
        minor=0
        if [[ "${line}" =~ ([0-9]+)(\.([0-9]+))? ]]; then
            major="$((10#${BASH_REMATCH[1]}))"
            if [[ -n "${BASH_REMATCH[3]:-}" ]]; then
                minor="$((10#${BASH_REMATCH[3]}))"
            fi
        fi

        tier=0
        if [[ "${line}" == *pro* ]]; then
            tier=3
        elif [[ "${line}" == *flash-lite* ]]; then
            tier=1
        elif [[ "${line}" == *flash* ]]; then
            tier=2
        fi

        printf -v key "%d%05d%05d%d_%s" "${is_latest}" "${major}" "${minor}" "${tier}" "${line}"
        keys+=("${key}")
    done

    local n="${#items[@]}"
    if [[ "${n}" -le 1 ]]; then
        if [[ "${n}" -eq 1 ]]; then
            printf '%s\n' "${items[0]}"
        fi
        return 0
    fi

    local i=0
    local j=0
    local tmp_item=""
    local tmp_key=""

    for ((i = 1; i < n; i++)); do
        tmp_key="${keys[i]}"
        tmp_item="${items[i]}"
        j=$((i - 1))
        while ((j >= 0)) && [[ "${keys[j]}" < "${tmp_key}" ]]; do
            keys[j + 1]="${keys[j]}"
            items[j + 1]="${items[j]}"
            ((j--))
        done
        keys[j + 1]="${tmp_key}"
        items[j + 1]="${tmp_item}"
    done

    for ((i = 0; i < n; i++)); do
        printf '%s\n' "${items[i]}"
    done
}
