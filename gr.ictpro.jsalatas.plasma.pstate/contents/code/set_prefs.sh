#!/bin/bash

# Reads and changes the CPU, Intel GPU and vendor specific power settings.
# The widget runs it through sudo, see 99-plasma-pstate.

# PLASMA_PSTATE_SYSFS lets the widget run against a fake sysfs tree for
# testing. It is ignored when running as root, so it can't be abused through
# the sudoers rule.
SYSFS=/sys
if [ "$EUID" -ne 0 ] && [ -n "$PLASMA_PSTATE_SYSFS" ]; then
    SYSFS=$PLASMA_PSTATE_SYSFS
fi

CPU=$SYSFS/devices/system/cpu
INTEL_PSTATE=$CPU/intel_pstate
GPU=$SYSFS/class/drm/card0
LG_LAPTOP=$SYSFS/devices/platform/lg-laptop

# write <value> <file>...
write() {
    local value=$1 file
    shift
    for file in "$@"; do
        printf '%s\n' "$value" > "$file" || return
    done
}

# write_nonzero <value> <file>: like write, but ignores 0
write_nonzero() {
    if [ "$1" != "0" ]; then
        write "$1" "$2"
    fi
}

# write_bool <value> <file> <value for true> <value for false>
write_bool() {
    if [ "$1" == "true" ]; then
        write "$3" "$2"
    else
        write "$4" "$2"
    fi
}

# read_bool <file> <value for false>: prints true unless the file holds the
# value for false
read_bool() {
    if [ "$(cat "$1" 2> /dev/null)" == "$2" ]; then
        echo false
    else
        echo true
    fi
}

has_dell_thermal() {
    smbios-thermal-ctl -g > /dev/null 2>&1
}

has_lg_laptop() {
    [ -d "$LG_LAPTOP" ]
}

has_nvidia() {
    nvidia-settings -q GpuPowerMizerMode > /dev/null 2>&1
}

set_energy_perf() {
    if [ -f "$CPU/cpu0/cpufreq/energy_performance_preference" ]; then
        write "$1" "$CPU"/cpu*/cpufreq/energy_performance_preference
    else
        local pnum
        pnum=$(echo "$1" | sed -r 's/^performance$/0/;
                                   s/^balance_performance$/4/;
                                   s/^(default|normal)$/6/;
                                   s/^balance_power?$/8/;
                                   s/^power(save)?$/15/')
        x86_energy_perf_policy "$pnum" > /dev/null 2>&1
    fi
}

read_energy_perf() {
    local epp
    epp=$(cat "$CPU/cpu0/cpufreq/energy_performance_preference" 2> /dev/null)
    if [ -z "$epp" ]; then
        epp=$(x86_energy_perf_policy -r 2> /dev/null | grep -v 'HWP_' | \
              sed -r 's/://;
                      s/(0x0000000000000000|EPB 0)/performance/;
                      s/(0x0000000000000004|EPB 4)/balance_performance/;
                      s/(0x0000000000000006|EPB 6)/default/;
                      s/(0x0000000000000008|EPB 8)/balance_power/;
                      s/(0x000000000000000f|EPB 15)/power/' | \
              awk '{ printf "%s\n", $2; }' | head -n 1)
    fi
    echo "$epp"
}

read_thermal_mode() {
    smbios-thermal-ctl -g | grep -C 1 "Current Thermal Modes:" | tail -n 1 | \
        awk '{$1=$1;print}' | sed "s/\t//g; s/ /-/g" | tr "[A-Z]" "[a-z]"
}

read_powermizer() {
    nvidia-settings -q GpuPowerMizerMode | grep "Attribute 'GPUPowerMizerMode'" | \
        awk -F "): " '{print $2}' | awk -F "." '{print $1}'
}

read_all() {
    local fields=()

    # field <name> <value>
    field() {
        fields+=("\"$1\":\"$2\"")
    }

    field cpu_min_perf "$(cat "$INTEL_PSTATE/min_perf_pct" 2> /dev/null)"
    field cpu_max_perf "$(cat "$INTEL_PSTATE/max_perf_pct" 2> /dev/null)"
    field cpu_turbo "$(read_bool "$INTEL_PSTATE/no_turbo" 1)"
    field gpu_min_freq "$(cat "$GPU/gt_min_freq_mhz" 2> /dev/null)"
    field gpu_max_freq "$(cat "$GPU/gt_max_freq_mhz" 2> /dev/null)"
    field gpu_min_limit "$(cat "$GPU/gt_RP1_freq_mhz" 2> /dev/null)"
    field gpu_max_limit "$(cat "$GPU/gt_RP0_freq_mhz" 2> /dev/null)"
    field gpu_boost_freq "$(cat "$GPU/gt_boost_freq_mhz" 2> /dev/null)"
    field gpu_cur_freq "$(cat "$GPU/gt_cur_freq_mhz" 2> /dev/null)"
    field cpu_governor "$(cat "$CPU/cpu0/cpufreq/scaling_governor" 2> /dev/null)"
    field energy_perf "$(read_energy_perf)"

    if has_dell_thermal; then
        field thermal_mode "$(read_thermal_mode)"
    fi

    if has_lg_laptop; then
        if [ "$(cat "$LG_LAPTOP/battery_care_limit")" == "80" ]; then
            field lg_battery_charge_limit true
        else
            field lg_battery_charge_limit false
        fi
        field lg_usb_charge "$(read_bool "$LG_LAPTOP/usb_charge" 0)"
        field lg_fan_mode "$(read_bool "$LG_LAPTOP/fan_mode" 1)"
    fi

    if has_nvidia; then
        field powermizer "$(read_powermizer)"
    fi

    local IFS=,
    echo "{${fields[*]}}"
}

usage() {
    echo "Usage:"
    echo "1: set_prefs.sh [ -cpu-min-perf |"
    echo "                  -cpu-max-perf |"
    echo "                  -cpu-turbo |"
    echo "                  -gpu-min-freq |"
    echo "                  -gpu-max-freq |"
    echo "                  -gpu-boost-freq |"
    echo "                  -cpu-governor |"
    echo "                  -energy-perf |"
    echo "                  -thermal-mode |"
    echo "                  -lg-battery-charge-limit |"
    echo "                  -lg-fan-mode |"
    echo "                  -lg-usb-charge |"
    echo "                  -powermizer ] value"
    echo "2: set_prefs.sh -read-all"
    exit 3
}

# This runs as root, so only accept the values the widget can send.
PERCENT='[0-9]|[1-9][0-9]|100'
MHZ='[0-9]{1,5}'
BOOL='true|false'
GOVERNOR='[a-z_]+'
ENERGY_PERF='default|performance|balance_performance|balance_power|power'
THERMAL_MODE='performance|balanced|cool-bottom|quiet'
POWERMIZER='[0-2]'

# accept <regex>: exits unless the value matches regex
accept() {
    if ! [[ $value =~ ^($1)$ ]]; then
        echo "set_prefs.sh: invalid value for $option: '$value'" >&2
        exit 2
    fi
}

option=$1
value=$2

case $option in
    -cpu-min-perf)            accept "$PERCENT";      write_nonzero "$value" "$INTEL_PSTATE/min_perf_pct" ;;
    -cpu-max-perf)            accept "$PERCENT";      write_nonzero "$value" "$INTEL_PSTATE/max_perf_pct" ;;
    -cpu-turbo)               accept "$BOOL";         write_bool "$value" "$INTEL_PSTATE/no_turbo" 0 1 ;;
    -gpu-min-freq)            accept "$MHZ";          write_nonzero "$value" "$GPU/gt_min_freq_mhz" ;;
    -gpu-max-freq)            accept "$MHZ";          write_nonzero "$value" "$GPU/gt_max_freq_mhz" ;;
    -gpu-boost-freq)          accept "$MHZ";          write_nonzero "$value" "$GPU/gt_boost_freq_mhz" ;;
    -cpu-governor)            accept "$GOVERNOR";     write "$value" "$CPU"/cpu*/cpufreq/scaling_governor ;;
    -energy-perf)             accept "$ENERGY_PERF";  set_energy_perf "$value" ;;
    -thermal-mode)            accept "$THERMAL_MODE"; smbios-thermal-ctl --set-thermal-mode="$value" 2> /dev/null ;;
    -lg-battery-charge-limit) accept "$BOOL";         write_bool "$value" "$LG_LAPTOP/battery_care_limit" 80 100 ;;
    -lg-fan-mode)             accept "$BOOL";         write_bool "$value" "$LG_LAPTOP/fan_mode" 0 1 ;;
    -lg-usb-charge)           accept "$BOOL";         write_bool "$value" "$LG_LAPTOP/usb_charge" 1 0 ;;
    -powermizer)              accept "$POWERMIZER";   nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=$value" 2> /dev/null ;;
    -read-all)                read_all ;;
    *)                        usage ;;
esac
