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

# drm_card <PCI vendor id>: prints the directory of the first DRM card from
# that vendor
drm_card() {
    grep -H "$1" "$SYSFS"/class/drm/card?/device/vendor 2> /dev/null | \
        head -n1 | sed 's/\/device\/vendor:.*//'
}

CPU=$SYSFS/devices/system/cpu
INTEL_PSTATE=$CPU/intel_pstate
GPU=$(drm_card 0x8086)
NVIDIA_GPU=$(drm_card 0x10de)

# Intel's Running Average Power Limit of the CPU package
INTEL_RAPL=$(grep -H "package-0" "$SYSFS"/class/powercap/intel-rapl/*/name 2> /dev/null | \
             head -n1 | sed 's/\/name:.*//')

# rapl_constraint <long_term|short_term>: prints the start of the constraint's
# file names
rapl_constraint() {
    if [ -n "$INTEL_RAPL" ]; then
        grep -H "$1" "$INTEL_RAPL"/constraint_*_name 2> /dev/null | \
            head -n1 | sed 's/_name:.*//'
    fi
}

RAPL_LONG=$(rapl_constraint long_term)
RAPL_SHORT=$(rapl_constraint short_term)

# read_watts <file>: prints the microwatts in file as watts
read_watts() {
    if [ -f "$1" ]; then
        echo $(( $(cat "$1") / 1000000 ))
    fi
}

# rapl_max <constraint> <default>: the most watts a limit may be set to,
# which the hardware may not tell
rapl_max() {
    local max
    max=$(read_watts "$1_max_power_uw")
    if [ -n "$1" ] && [ "${max:-0}" -gt 0 ]; then
        echo "$max"
    elif [ -n "$1" ]; then
        echo "$2"
    fi
}

RAPL_LONG_MAX=$(rapl_max "$RAPL_LONG" 100)
RAPL_SHORT_MAX=$(rapl_max "$RAPL_SHORT" 200)

# set_rapl <watts> <constraint>
set_rapl() {
    write $(( $1 * 1000000 )) "$2_power_limit_uw" && write 1 "$INTEL_RAPL/enabled"
}

# Turbo is switched with the generic cpufreq boost, intel_pstate's no_turbo or
# AMD's cpb
if [ -f "$CPU/cpufreq/boost" ]; then
    TURBO=$CPU/cpufreq/boost
    TURBO_ON=1
    TURBO_OFF=0
elif [ -f "$INTEL_PSTATE/no_turbo" ]; then
    TURBO=$INTEL_PSTATE/no_turbo
    TURBO_ON=0
    TURBO_OFF=1
elif [ -f "$CPU/cpufreq/policy0/cpb" ]; then
    TURBO=$CPU/cpufreq/policy0/cpb
    TURBO_ON=1
    TURBO_OFF=0
fi
LG_LAPTOP=$SYSFS/devices/platform/lg-laptop
# Intel's Thermal Control Circuit offset, lowering the throttling temperature
INTEL_TCC=$(grep -H "TCC Offset" "$SYSFS"/class/thermal/*/type 2> /dev/null | \
            head -n1 | sed 's/\/type:.*//')

# write <value> <file>...: only writes to existing files
write() {
    local value=$1 file
    shift
    for file in "$@"; do
        if [ ! -f "$file" ]; then
            echo "set_prefs.sh: $file doesn't exist" >&2
            return 1
        fi
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

# Asking nvidia-settings wakes up the GPU, so this isn't part of read_all. It
# doesn't need root.
read_powermizer() {
    local powermizer
    if [ -n "$NVIDIA_GPU" ]; then
        powermizer=$(nvidia-settings -q GpuPowerMizerMode 2> /dev/null | \
            grep "Attribute 'GPUPowerMizerMode'" | \
            awk -F "): " '{print $2}' | awk -F "." '{print $1}')
    fi
    if [ -n "$powermizer" ]; then
        echo "{\"powermizer\":\"$powermizer\"}"
    else
        echo "{}"
    fi
}

read_all() {
    local fields=()

    # field <name> <value>: adds a setting, unless the hardware lacks it
    field() {
        if [ -n "$2" ]; then
            fields+=("\"$1\":\"$2\"")
        fi
    }

    field cpu_min_perf "$(cat "$INTEL_PSTATE/min_perf_pct" 2> /dev/null)"
    field cpu_max_perf "$(cat "$INTEL_PSTATE/max_perf_pct" 2> /dev/null)"
    if [ -n "$TURBO" ]; then
        field cpu_turbo "$(read_bool "$TURBO" "$TURBO_OFF")"
    fi
    field gpu_min_freq "$(cat "$GPU/gt_min_freq_mhz" 2> /dev/null)"
    field gpu_max_freq "$(cat "$GPU/gt_max_freq_mhz" 2> /dev/null)"
    field gpu_min_limit "$(cat "$GPU/gt_RP1_freq_mhz" 2> /dev/null)"
    field gpu_max_limit "$(cat "$GPU/gt_RP0_freq_mhz" 2> /dev/null)"
    field gpu_boost_freq "$(cat "$GPU/gt_boost_freq_mhz" 2> /dev/null)"
    field gpu_cur_freq "$(cat "$GPU/gt_cur_freq_mhz" 2> /dev/null)"
    field cpu_governor "$(cat "$CPU/cpu0/cpufreq/scaling_governor" 2> /dev/null)"
    field cpu_available_governors "$(cat "$CPU/cpu0/cpufreq/scaling_available_governors" 2> /dev/null)"
    field energy_perf "$(read_energy_perf)"

    if has_dell_thermal; then
        field thermal_mode "$(read_thermal_mode)"
    fi

    field intel_rapl_long "$(read_watts "${RAPL_LONG}_power_limit_uw")"
    field intel_rapl_long_max "$RAPL_LONG_MAX"
    field intel_rapl_short "$(read_watts "${RAPL_SHORT}_power_limit_uw")"
    field intel_rapl_short_max "$RAPL_SHORT_MAX"

    field intel_tcc_cur_state "$(cat "$INTEL_TCC/cur_state" 2> /dev/null)"
    field intel_tcc_max_state "$(cat "$INTEL_TCC/max_state" 2> /dev/null)"

    # Whether the Nvidia GPU is active or suspended, read without waking it up
    field nvidia_runtime_status "$(cat "$NVIDIA_GPU/device/power/runtime_status" 2> /dev/null)"

    if has_lg_laptop; then
        if [ "$(cat "$LG_LAPTOP/battery_care_limit")" == "80" ]; then
            field lg_battery_charge_limit true
        else
            field lg_battery_charge_limit false
        fi
        field lg_usb_charge "$(read_bool "$LG_LAPTOP/usb_charge" 0)"
        field lg_fan_mode "$(read_bool "$LG_LAPTOP/fan_mode" 1)"
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
    echo "                  -powermizer |"
    echo "                  -intel-tcc-cur-state |"
    echo "                  -intel-rapl-long |"
    echo "                  -intel-rapl-short ] value"
    echo "2: set_prefs.sh -read-all"
    echo "3: set_prefs.sh -read-powermizer"
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
TCC='[0-9]{1,3}'
WATTS='[1-9][0-9]{0,3}'

# accept <regex>: exits unless the value matches regex
accept() {
    if ! [[ $value =~ ^($1)$ ]]; then
        echo "set_prefs.sh: invalid value for $option: '$value'" >&2
        exit 2
    fi
}

# accept_at_most <number>: exits unless the value is at most number
accept_at_most() {
    if [ -n "$1" ] && [ "$value" -gt "$1" ]; then
        echo "set_prefs.sh: $value is too large for $option" >&2
        exit 2
    fi
}

# accept_listed <file>: exits unless the value is one of the words in file,
# if it exists
accept_listed() {
    if [ -f "$1" ] && ! [[ " $(cat "$1") " == *" $value "* ]]; then
        echo "set_prefs.sh: $value isn't available for $option" >&2
        exit 2
    fi
}

option=$1
value=$2

case $option in
    -cpu-min-perf)            accept "$PERCENT";      write_nonzero "$value" "$INTEL_PSTATE/min_perf_pct" ;;
    -cpu-max-perf)            accept "$PERCENT";      write_nonzero "$value" "$INTEL_PSTATE/max_perf_pct" ;;
    -cpu-turbo)               accept "$BOOL";         write_bool "$value" "$TURBO" "$TURBO_ON" "$TURBO_OFF" ;;
    -gpu-min-freq)            accept "$MHZ";          write_nonzero "$value" "$GPU/gt_min_freq_mhz" ;;
    -gpu-max-freq)            accept "$MHZ";          write_nonzero "$value" "$GPU/gt_max_freq_mhz" ;;
    -gpu-boost-freq)          accept "$MHZ";          write_nonzero "$value" "$GPU/gt_boost_freq_mhz" ;;
    -cpu-governor)            accept "$GOVERNOR";     accept_listed "$CPU/cpu0/cpufreq/scaling_available_governors"; write "$value" "$CPU"/cpu*/cpufreq/scaling_governor ;;
    -energy-perf)             accept "$ENERGY_PERF";  set_energy_perf "$value" ;;
    -thermal-mode)            accept "$THERMAL_MODE"; smbios-thermal-ctl --set-thermal-mode="$value" 2> /dev/null ;;
    -lg-battery-charge-limit) accept "$BOOL";         write_bool "$value" "$LG_LAPTOP/battery_care_limit" 80 100 ;;
    -lg-fan-mode)             accept "$BOOL";         write_bool "$value" "$LG_LAPTOP/fan_mode" 0 1 ;;
    -lg-usb-charge)           accept "$BOOL";         write_bool "$value" "$LG_LAPTOP/usb_charge" 1 0 ;;
    -powermizer)              accept "$POWERMIZER";   nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=$value" 2> /dev/null ;;
    -intel-tcc-cur-state)     accept "$TCC";          accept_at_most "$(cat "$INTEL_TCC/max_state" 2> /dev/null)"; write "$value" "$INTEL_TCC/cur_state" ;;
    -intel-rapl-long)         accept "$WATTS";        accept_at_most "$RAPL_LONG_MAX"; set_rapl "$value" "$RAPL_LONG" ;;
    -intel-rapl-short)        accept "$WATTS";        accept_at_most "$RAPL_SHORT_MAX"; set_rapl "$value" "$RAPL_SHORT" ;;
    -read-all)                read_all ;;
    -read-powermizer)         read_powermizer ;;
    *)                        usage ;;
esac
