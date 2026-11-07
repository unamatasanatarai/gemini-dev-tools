#!/usr/bin/env bash
# Smoke tests for the suite. Runs every check under each available bash (PATH bash and /bin/bash),
# so Bash 3.2 regressions on stock macOS are caught. No network access: curl is stubbed.

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    printf 'smoke: not inside a git repository\n' >&2
    exit 1
}
cd "${repo_root}" || exit 1

work_dir="$(mktemp -d)" || exit 1
trap 'rm -rf "${work_dir}"' EXIT
mkdir -p "${work_dir}/bin" "${work_dir}/cfg"
cat >"${work_dir}/bin/curl" <<'EOF'
#!/bin/sh
printf '%s' '{"models":[{"name":"models/gemini-2.5-flash","supportedGenerationMethods":["generateContent"]},{"name":"models/gemini-3.5-flash","supportedGenerationMethods":["generateContent"]},{"name":"models/gemini-2.5-flash","supportedGenerationMethods":["generateContent"]},{"name":"models/embedding-001","supportedGenerationMethods":["embedContent"]}]}'
EOF
chmod +x "${work_dir}/bin/curl"

failures=0
fail() {
    printf 'FAIL [%s]: %s\n' "${shell_bin}" "$1" >&2
    failures=$((failures + 1))
}

shells=("$(command -v bash)")
[[ -x /bin/bash && "/bin/bash" != "${shells[0]}" ]] && shells+=("/bin/bash")

scripts=()
while IFS= read -r f; do
    [[ -n "${f}" ]] && scripts+=("${f}")
done <<<"$(git ls-files -- 'gemini-*' 'gg*' install.sh .release.sh tests/smoke.sh)"

for shell_bin in "${shells[@]}"; do
    printf '==> %s (%s)\n' "${shell_bin}" "$("${shell_bin}" -c 'printf %s "${BASH_VERSION}"')"

    for f in "${scripts[@]}"; do
        "${shell_bin}" -n "${f}" || fail "syntax: ${f}"
    done

    got="$(XDG_CONFIG_HOME="${work_dir}/cfg" "${shell_bin}" -c '
        source ./gemini-common.sh
        a=(" gemini-2.5-flash" gemini-flash-latest "# comment" gemini-3.5-flash "" gemini-2.5-flash gemini-2.5-pro)
        gemini_sort_models a
        printf "%s|" "${a[@]}"' 2>&1)"
    [[ "${got}" == "gemini-flash-latest|gemini-3.5-flash|gemini-2.5-pro|gemini-2.5-flash|" ]] ||
        fail "gemini_sort_models: ${got}"

    got="$(XDG_CONFIG_HOME="${work_dir}/cfg" "${shell_bin}" -c '
        source ./gemini-common.sh
        b=(pre)
        gemini_lines_to_array b "one
two words

three"
        printf "%s|" "${b[@]}"' 2>&1)"
    [[ "${got}" == "pre|one|two words|three|" ]] || fail "gemini_lines_to_array: ${got}"

    got="$(PATH="${work_dir}/bin:${PATH}" XDG_CONFIG_HOME="${work_dir}/cfg" GEMINI_API_KEY=dummy \
        "${shell_bin}" ./gemini-list-models 2>&1)"
    [[ "${got}" == $'gemini-3.5-flash\ngemini-2.5-flash' ]] || fail "gemini-list-models: ${got}"

    rm -f "${work_dir}/cfg/gemini/rotation"
    got="$(XDG_CONFIG_HOME="${work_dir}/cfg" "${shell_bin}" ./gemini-rotate-models --set \
        gemini-2.5-flash,gemini-3.8-flash,gemini-2.5-flash 2>&1)" || fail "gemini-rotate-models --set exit status"
    got="$(cat "${work_dir}/cfg/gemini/rotation" 2>&1)"
    [[ "${got}" == $'gemini-3.8-flash\ngemini-2.5-flash' ]] || fail "gemini-rotate-models --set: ${got}"

    for tool in gemini-key gemini-list-models gemini-rotate-models gemini-prompt gemini-commit-message ggic gemini-release-notes ggrel; do
        XDG_CONFIG_HOME="${work_dir}/cfg" "${shell_bin}" "./${tool}" --help >/dev/null 2>&1 || fail "${tool} --help"
    done
done

if ((failures > 0)); then
    printf '%d smoke test(s) failed\n' "${failures}" >&2
    exit 1
fi
printf 'All smoke tests passed\n'
