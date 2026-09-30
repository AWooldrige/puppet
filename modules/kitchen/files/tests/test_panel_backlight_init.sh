#!/bin/bash
#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
#
# Tests panel-backlight-init against a fake sysfs tree. Run directly, or via
# `make test` from the repo root.

set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/raspi/files/touchdisplay/panel-backlight-init"

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

assert_file_contents() {
    local path="$1" expected="$2" what="$3"
    local actual
    if [[ ! -f "${path}" ]]; then
        fail "${what}: ${path} does not exist"
        return
    fi
    actual="$(<"${path}")"
    if [[ "${actual}" == "${expected}" ]]; then
        pass "${what}"
    else
        fail "${what}: expected '${expected}', got '${actual}'"
    fi
}

# A fake backlight that looks like the panel does at boot: powered down,
# brightness 0.
make_device() {
    local root="$1" name="$2" max="$3"
    mkdir -p "${root}/${name}"
    echo "${max}" > "${root}/${name}/max_brightness"
    echo 0 > "${root}/${name}/brightness"
    echo 4 > "${root}/${name}/bl_power"
}

run_script() {
    local root="$1"
    PANEL_BACKLIGHT_SYSFS_ROOT="${root}" \
    PANEL_BACKLIGHT_SKIP_CHOWN=1 \
        "${SCRIPT}" > /dev/null 2>&1
}

test_sets_full_brightness_and_unblanks() {
    local root
    root="$(mktemp -d)"
    make_device "${root}" 'panel_backlight@1' 31

    run_script "${root}"
    local rc=$?

    if (( rc == 0 )); then
        pass 'exits 0 on a healthy device'
    else
        fail "exits 0 on a healthy device: got ${rc}"
    fi

    assert_file_contents "${root}/panel_backlight@1/brightness" '31' \
        'max_brightness is written to brightness'
    assert_file_contents "${root}/panel_backlight@1/bl_power" '0' \
        'bl_power is set to 0 (FB_BLANK_UNBLANK)'

    rm -rf "${root}"
}

test_ignores_other_backlights() {
    local root
    root="$(mktemp -d)"
    make_device "${root}" 'panel_backlight@1' 255
    make_device "${root}" 'rpi_backlight' 255

    run_script "${root}"

    assert_file_contents "${root}/panel_backlight@1/brightness" '255' \
        'the panel is configured'
    assert_file_contents "${root}/rpi_backlight/brightness" '0' \
        'a non-matching backlight is left alone'

    rm -rf "${root}"
}

test_fails_when_no_device() {
    local root
    root="$(mktemp -d)"

    run_script "${root}"
    local rc=$?

    if (( rc != 0 )); then
        pass 'non-zero exit when no matching backlight exists'
    else
        fail 'non-zero exit when no matching backlight exists: got 0'
    fi

    rm -rf "${root}"
}

test_fails_on_bogus_max_brightness() {
    local root
    root="$(mktemp -d)"
    make_device "${root}" 'panel_backlight@1' 0

    run_script "${root}"
    local rc=$?

    if (( rc != 0 )); then
        pass 'non-zero exit when max_brightness is 0'
    else
        fail 'non-zero exit when max_brightness is 0: got 0'
    fi

    assert_file_contents "${root}/panel_backlight@1/bl_power" '4' \
        'a device with a bogus max_brightness is left blanked, not half-configured'

    rm -rf "${root}"
}

if [[ ! -x "${SCRIPT}" ]]; then
    echo "FAIL: ${SCRIPT} is missing or not executable"
    exit 1
fi

test_sets_full_brightness_and_unblanks
test_ignores_other_backlights
test_fails_when_no_device
test_fails_on_bogus_max_brightness

echo
echo "panel-backlight-init: ${passes} passed, ${failures} failed"
(( failures == 0 ))
