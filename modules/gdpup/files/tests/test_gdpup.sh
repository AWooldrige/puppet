#!/bin/bash
#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
#
# Tests the toggle and disabled-too-long behaviour of gdpup against a stub
# wpu_shell. Run directly, or via `make test` from the repo root.
#
# Only the disabled path is exercised. An enabled run clones a repo and applies
# a catalogue, which is not something to do on a workstation.

set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/gdpup"

failures=0
passes=0

fail() {
    echo "FAIL: $*"
    failures=$((failures + 1))
}

pass() {
    echo "ok: $*"
    passes=$((passes + 1))
}

assert_contains() {
    local haystack="$1" needle="$2" what="$3"
    if [[ "${haystack}" == *"${needle}"* ]]; then
        pass "${what}"
    else
        fail "${what}: '${needle}' not in '${haystack}'"
    fi
}

assert_empty() {
    local actual="$1" what="$2"
    if [[ -z "${actual}" ]]; then
        pass "${what}"
    else
        fail "${what}: expected nothing, got '${actual}'"
    fi
}

# Stands in for /usr/share/wpu/wpu_shell. escalate appends to a file so the test
# can tell whether it was called and with what. Omitting it models a workstation,
# where the escalate class is not included.
make_wpu_shell() {
    local path="$1" with_escalate="$2"
    cat > "${path}" <<'EOF'
function log { echo "$1"; }
function is_toggle_off { [ "${FAKE_TOGGLE}" == "off" ]; }
function escalate_if_anything_fails { echo "TRAPPED: ${BASH_COMMAND}"; }
EOF
    if [[ "${with_escalate}" == 'with-escalate' ]]; then
        echo 'function escalate { echo "$1" >> "${ESCALATE_LOG}"; }' >> "${path}"
    fi
}

# Runs gdpup in a scratch directory. Echoes its stdout; leaves the escalate calls
# in ${scratch}/escalations and the marker at ${scratch}/disabled-since.
run_gdpup() {
    local scratch="$1" toggle="$2" marker_age="$3" with_escalate="$4"
    shift 4

    make_wpu_shell "${scratch}/wpu_shell" "${with_escalate}"
    : > "${scratch}/escalations"
    if [[ -n "${marker_age}" ]]; then
        touch -d "${marker_age}" "${scratch}/disabled-since"
    fi

    # A checkout that looks already cloned, so an enabled run neither wipes
    # /etc/gdpup nor fetches from GitHub. It stops at the first git command.
    mkdir -p "${scratch}/checkout/manifests"
    : > "${scratch}/checkout/manifests/nodes.pp"

    FAKE_TOGGLE="${toggle}" \
    ESCALATE_LOG="${scratch}/escalations" \
    WPU_SHELL="${scratch}/wpu_shell" \
    GDPUP_DIR="${scratch}/checkout" \
    GDPUP_DISABLED_MARKER="${scratch}/disabled-since" \
        "${SCRIPT}" "$@" 2>&1
}

test_disabled_creates_the_marker_and_stays_quiet() {
    local scratch output
    scratch="$(mktemp -d)"

    output="$(run_gdpup "${scratch}" off '' with-escalate -f)"

    if [[ -f "${scratch}/disabled-since" ]]; then
        pass 'the marker is created the first time gdpup finds itself disabled'
    else
        fail 'the marker is created the first time gdpup finds itself disabled'
    fi
    assert_contains "${output}" 'for 0 days' 'the day count starts at zero'
    assert_empty "$(<"${scratch}/escalations")" 'nothing is escalated on day zero'

    rm -rf "${scratch}"
}

test_the_nightly_run_warns_after_five_days() {
    local scratch output
    scratch="$(mktemp -d)"

    output="$(run_gdpup "${scratch}" off '6 days ago' with-escalate -f)"

    assert_contains "$(<"${scratch}/escalations")" 'disabled in /etc/toggles.toml for 6 days' \
        'the nightly run escalates once past five days'
    if [[ "${output}" != *'Running puppet apply'* ]]; then
        pass 'a forced run does not bypass the toggle'
    else
        fail 'a forced run does not bypass the toggle'
    fi

    rm -rf "${scratch}"
}

test_the_twenty_minute_run_does_not_warn() {
    local scratch
    scratch="$(mktemp -d)"

    run_gdpup "${scratch}" off '6 days ago' with-escalate > /dev/null

    assert_empty "$(<"${scratch}/escalations")" \
        'the frequent run stays silent, so a host nags at most once a day'

    rm -rf "${scratch}"
}

test_a_host_without_escalate_only_logs() {
    local scratch output rc
    scratch="$(mktemp -d)"

    output="$(run_gdpup "${scratch}" off '6 days ago' no-escalate -f)"
    rc=$?

    if (( rc == 0 )); then
        pass 'a host with no escalate command exits cleanly'
    else
        fail "a host with no escalate command exits cleanly: got ${rc}"
    fi
    assert_contains "${output}" 'for 6 days' 'it still logs the day count'
    if [[ "${output}" != *'TRAPPED'* ]]; then
        pass 'the missing escalate does not trip the ERR trap'
    else
        fail "the missing escalate does not trip the ERR trap: ${output}"
    fi

    rm -rf "${scratch}"
}

test_enabling_clears_the_marker() {
    local scratch
    scratch="$(mktemp -d)"

    # An enabled run carries on into git and fails there, since the fake checkout is
    # not a repository. All that matters is that it got past the toggle and tidied
    # the marker up on the way.
    run_gdpup "${scratch}" on '6 days ago' with-escalate > /dev/null

    if [[ ! -f "${scratch}/disabled-since" ]]; then
        pass 'the marker is removed once the toggle is back on'
    else
        fail 'the marker is removed once the toggle is back on'
    fi

    rm -rf "${scratch}"
}

if [[ ! -x "${SCRIPT}" ]]; then
    echo "FAIL: ${SCRIPT} is missing or not executable"
    exit 1
fi

test_disabled_creates_the_marker_and_stays_quiet
test_the_nightly_run_warns_after_five_days
test_the_twenty_minute_run_does_not_warn
test_a_host_without_escalate_only_logs
test_enabling_clears_the_marker

echo
echo "gdpup: ${passes} passed, ${failures} failed"
(( failures == 0 ))
