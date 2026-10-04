#!/usr/bin/env bash
set -u

failures=0
checks=0
here="$(cd "$(dirname "$0")" && pwd)"
source "${here}/../wpu_shell"

check() {
    local expected="$1" content="$2" what="$3"
    checks=$((checks + 1))
    [[ -n "${content}" ]] && printf '%s' "${content}" > "${TOGGLES_FILE}"
    if is_toggle_off enabled_gdpup; then actual=off; else actual=on; fi
    if [[ "${actual}" == "${expected}" ]]; then
        echo "PASS: ${what}"
    else
        echo "FAIL: ${what}: expected ${expected}, got ${actual}"
        failures=$((failures + 1))
    fi
}

scratch="$(mktemp -d)"
export TOGGLES_FILE="${scratch}/toggles.toml"

check on  'enabled_gdpup = true'                      'true leaves it running'
check off 'enabled_gdpup = false'                     'false switches it off'
check off '  enabled_gdpup=false  '                   'spacing does not matter'
check on  '# enabled_gdpup = false'                   'a commented-out line does nothing'
check on  'enabled_gdpup = falsey'                    'only false itself counts'
check on  'other_enabled_gdpup = false'               'another switch with a similar name does nothing'
check on  'enabled_backups = false'                   'another switch does nothing'
check off $'enabled_backups = true\nenabled_gdpup = false' 'it is found among other switches'
rm -f "${TOGGLES_FILE}"
check on  ''                                          'a missing file leaves it running'
rm -rf "${scratch}"

echo "wpu_shell: ${checks} checks, ${failures} failed"
[[ "${failures}" -eq 0 ]]
