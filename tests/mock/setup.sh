#!/bin/bash
# Create a fake sysfs tree emulating an Intel laptop with an LG, Dell and
# Nvidia flavour, so the widget can be exercised on any machine. With amd,
# the CPU uses the generic cpufreq boost instead of intel_pstate, and there is
# no Intel GPU.
#
# Usage: setup.sh <dir> [intel|amd]
# Then export PLASMA_PSTATE_SYSFS=<dir>/sys and prepend tests/mock/bin to PATH.

set -e

ROOT=${1:?usage: setup.sh <dir> [intel|amd]}
CPU_VENDOR=${2:-intel}
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
    put "$d/scaling_available_governors" "performance powersave"
    put "$d/energy_performance_preference" balance_performance
done

g=$SYS/class/drm/card0
mkdir -p "$g/device"
put "$g/device/vendor" 0x8086
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

r=$SYS/class/powercap/intel-rapl
mkdir -p "$r/intel-rapl:0" "$r/intel-rapl:1"
put "$r/intel-rapl:1/name" psys
r=$r/intel-rapl:0
put "$r/name" package-0
put "$r/enabled" 0
put "$r/constraint_0_name" long_term
put "$r/constraint_0_power_limit_uw" 28000000
put "$r/constraint_0_max_power_uw" 45000000
put "$r/constraint_1_name" short_term
put "$r/constraint_1_power_limit_uw" 64000000
put "$r/constraint_1_max_power_uw" 0

for i in 0 1; do
    mkdir -p "$SYS/class/thermal/cooling_device$i"
done
put "$SYS/class/thermal/cooling_device0/type" Processor
t=$SYS/class/thermal/cooling_device1
put "$t/type" "TCC Offset"
put "$t/cur_state" 0
put "$t/max_state" 63

put "$ROOT/dell_thermal_mode" Balanced
n=$SYS/class/drm/card1
mkdir -p "$n/device"
put "$n/device/vendor" 0x10de
mkdir -p "$n/device/power"
put "$n/device/power/runtime_status" suspended
put "$ROOT/nvidia_powermizer" 2

if [ "$CPU_VENDOR" == amd ]; then
    rm -r "$SYS/devices/system/cpu/intel_pstate" "$SYS/class/drm/card0" "$SYS/class/thermal/cooling_device1"
    mkdir -p "$SYS/devices/system/cpu/cpufreq"
    put "$SYS/devices/system/cpu/cpufreq/boost" 1
    for d in "$SYS"/devices/system/cpu/cpu?/cpufreq; do
        put "$d/scaling_governor" schedutil
        put "$d/scaling_available_governors" "conservative ondemand userspace powersave performance schedutil"
        put "$d/scaling_available_frequencies" "3600000 2800000 2200000 "
        put "$d/scaling_min_freq" 2200000
        put "$d/scaling_max_freq" 3600000
    done
fi
