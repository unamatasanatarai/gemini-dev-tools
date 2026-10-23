#!/usr/bin/env bash
# gemini-common.sh - Shared configuration, authentication, and model utilities

gemini_config_dir() {
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/gemini"
}

gemini_cred_file() {
    printf '%s/credentials\n' "$(gemini_config_dir)"
}

gemini_rotation_file() {
    printf '%s/rotation\n' "$(gemini_config_dir)"
}

gemini_cache_dir() {
    printf '%s\n' "${XDG_CACHE_HOME:-$HOME/.cache}/gemini"
}

gemini_migrate_legacy() {
    local target_dir
    local cred_file
    local legacy_dir
    local legacy_key

    target_dir="$(gemini_config_dir)"
    cred_file="$(gemini_cred_file)"
    legacy_dir="${XDG_CONFIG_HOME:-$HOME/.config}/gemini-commit-message"
    legacy_key="${legacy_dir}/key"

    if [[ -d "${legacy_dir}" ]]; then
        if [[ ! -f "${cred_file}" && -f "${legacy_key}" ]]; then
            mkdir -p -m 0700 "${target_dir}" 2>/dev/null || true
            chmod 0700 "${target_dir}" 2>/dev/null || true
            cp "${legacy_key}" "${cred_file}" 2>/dev/null || true
            chmod 0600 "${cred_file}" 2>/dev/null || true
        fi
    fi
}

gemini_get_api_key() {
    local key=""
    local cred_file

    if [[ -n "${GEMINI_API_KEY:-}" ]]; then
        key="${GEMINI_API_KEY}"
    elif [[ -n "${GOOGLE_API_KEY:-}" ]]; then
        key="${GOOGLE_API_KEY}"
    else
        gemini_migrate_legacy
        cred_file="$(gemini_cred_file)"
        if [[ -f "${cred_file}" ]]; then
            IFS= read -r key <"${cred_file}" || true
        fi
    fi

    key="${key%"${key##*[![:space:]]}"}"
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key//$'\r'/}"
    key="${key//$'\n'/}"

    if [[ -n "${key}" ]]; then
        printf '%s' "${key}"
        return 0
    fi
    return 1
}

gemini_get_default_rotation() {
    cat <<'EOF'
gemini-pro-latest
gemini-flash-latest
gemini-flash-lite-latest
gemini-4-argon
gemini-3.8-flash
gemini-3.7-flash
gemini-3.6-flash
gemini-3.5-flash
gemini-3.5-flash-lite
gemini-3.1-flash-lite
gemini-2.5-pro
gemini-2.5-flash
gemini-2.5-flash-lite
EOF
}

gemini_get_rotation_models() {
    local rot_file
    local models=()
    local line=""

    rot_file="$(gemini_rotation_file)"

    if [[ -f "${rot_file}" ]]; then
        while IFS= read -r line || [[ -n "${line}" ]]; do
            line="${line%"${line##*[![:space:]]}"}"
            line="${line#"${line%%[![:space:]]*}"}"
            [[ -z "${line}" || "${line}" =~ ^# ]] && continue
            models+=("${line}")
        done <"${rot_file}"
    fi

    if [[ ${#models[@]} -gt 0 ]]; then
        printf '%s\n' "${models[@]}"
    else
        gemini_get_default_rotation
    fi
}

# The topmost model in the rotation list is always the default model
gemini_get_primary_model() {
    local cli_model="${1:-}"
    local top_model=""

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

    top_model="$(gemini_get_rotation_models | head -n 1 || true)"
    if [[ -n "${top_model}" ]]; then
        printf '%s\n' "${top_model}"
        return 0
    fi

    printf '%s\n' "gemini-pro-latest"
}

gemini_sort_models_newest_to_oldest() {
    awk '
    {
        m = $0
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", m)
        if (m == "" || m ~ /^#/) next

        is_latest = (m ~ /-latest$/ || m ~ /-latest/) ? 1 : 0
        major = 0
        minor = 0
        if (match(m, /[0-9]+(\.[0-9]+)?/)) {
            ver = substr(m, RSTART, RLENGTH)
            split(ver, vparts, ".")
            major = vparts[1] + 0
            minor = (length(vparts) > 1) ? vparts[2] + 0 : 0
        }
        tier = 0
        if (m ~ /pro/) tier = 3
        else if (m ~ /flash-lite/) tier = 1
        else if (m ~ /flash/) tier = 2
        printf("%d %05d %05d %d %s\n", is_latest, major, minor, tier, m)
    }
    ' | sort -k1,1nr -k2,2nr -k3,3nr -k4,4nr -k5,5r | awk '{print $5}'
}
