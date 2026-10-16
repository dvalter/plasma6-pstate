#!/bin/bash
# Create a fake sysfs tree emulating an Intel laptop with an LG, Dell and
# Nvidia flavour, so the widget can be exercised on any machine.
#
# Usage: setup.sh <dir>
# Then export PLASMA_PSTATE_SYSFS=<dir>/sys and prepend tests/mock/bin to PATH.

set -e

ROOT=${1:?usage: setup.sh <dir>}
SYS=$ROOT/sys

rm -rf "$ROOT"
mkdir -p "$SYS/devices/system/cpu/intel_pstate" "$SYS/class/drm/card0" "$SYS/devices/platform/lg-laptop"

put() { printf '%s\n' "$2" > "$1"; }

put "$SYS/devices/system/cpu/intel_pstate/min_perf_pct" 20
put "$SYS/devices/system/cpu/intel_pstate/max_perf_pct" 100
put "$SYS/devices/system/cpu/intel_pstate/no_turbo" 0

for i in 0 1 2 3; do
    d=$SYS/devices/system/cpu/cpu$i/cpufreq
    mkdir -p "$d"
    put "$d/scaling_governor" powersave
    put "$d/energy_performance_preference" balance_performance
done

g=$SYS/class/drm/card0
put "$g/gt_RP1_freq_mhz" 300
put "$g/gt_RP0_freq_mhz" 1100
put "$g/gt_min_freq_mhz" 300
put "$g/gt_max_freq_mhz" 1100
put "$g/gt_boost_freq_mhz" 1100
put "$g/gt_cur_freq_mhz" 450

l=$SYS/devices/platform/lg-laptop
put "$l/fan_mode" 0
put "$l/battery_care_limit" 100
put "$l/usb_charge" 1

put "$ROOT/dell_thermal_mode" Balanced
put "$ROOT/nvidia_powermizer" 2
