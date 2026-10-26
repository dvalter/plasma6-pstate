#!/bin/bash
# Exercise set_prefs.sh against the mock sysfs tree and mock vendor tools.

HERE=$(cd "$(dirname "$0")" && pwd)
SCRIPT=$HERE/../gr.ictpro.jsalatas.plasma.pstate/contents/code/set_prefs.sh
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

"$HERE/mock/setup.sh" "$WORK"
export PLASMA_PSTATE_SYSFS=$WORK/sys
export PATH=$HERE/mock/bin:$PATH

failures=0

# check <description> <key> <expected>: compare a key of -read-all output
check() {
    local actual
    actual=$("$SCRIPT" -read-all | python3 -c "import json,sys; print(json.load(sys.stdin).get('$2', '<missing>'))")
    if [ "$actual" == "$3" ]; then
        echo "ok   - $1"
    else
        echo "FAIL - $1: $2 is '$actual', expected '$3'"
        failures=$((failures + 1))
    fi
}

"$SCRIPT" -read-all | python3 -m json.tool > /dev/null || { echo "FAIL - -read-all is not valid JSON"; exit 1; }
echo "ok   - -read-all is valid JSON"

check "initial cpu min perf"       cpu_min_perf 20
check "initial turbo"              cpu_turbo true
check "initial gpu limits"         gpu_max_limit 1100
check "initial governor"           cpu_governor powersave
check "initial energy perf"        energy_perf balance_performance
check "initial dell thermal mode"  thermal_mode balanced
check "initial lg battery limit"   lg_battery_charge_limit false
check "initial lg usb charge"      lg_usb_charge true
check "initial lg fan mode"        lg_fan_mode true
check "initial nvidia powermizer"  powermizer 2

"$SCRIPT" -cpu-min-perf 35;              check "set cpu min perf"      cpu_min_perf 35
"$SCRIPT" -cpu-max-perf 80;              check "set cpu max perf"      cpu_max_perf 80
"$SCRIPT" -cpu-min-perf 0;               check "min perf 0 is ignored" cpu_min_perf 35
"$SCRIPT" -cpu-turbo false;              check "disable turbo"         cpu_turbo false
"$SCRIPT" -gpu-min-freq 400;             check "set gpu min freq"      gpu_min_freq 400
"$SCRIPT" -gpu-max-freq 900;             check "set gpu max freq"      gpu_max_freq 900
"$SCRIPT" -gpu-boost-freq 1000;          check "set gpu boost freq"    gpu_boost_freq 1000
"$SCRIPT" -cpu-governor performance;     check "set governor"          cpu_governor performance
"$SCRIPT" -energy-perf power;            check "set energy perf"       energy_perf power
"$SCRIPT" -thermal-mode cool-bottom;     check "set dell thermal mode" thermal_mode cool-bottom
"$SCRIPT" -lg-battery-charge-limit true; check "set lg battery limit"  lg_battery_charge_limit true
"$SCRIPT" -lg-usb-charge false;          check "set lg usb charge"     lg_usb_charge false
"$SCRIPT" -lg-fan-mode false;            check "set lg fan mode"       lg_fan_mode false
"$SCRIPT" -powermizer 1;                 check "set nvidia powermizer" powermizer 1

for cpu in 0 1 2 3; do
    gov=$(cat "$PLASMA_PSTATE_SYSFS/devices/system/cpu/cpu$cpu/cpufreq/scaling_governor")
    [ "$gov" == "performance" ] || { echo "FAIL - governor not applied to cpu$cpu"; failures=$((failures + 1)); }
done
echo "ok   - governor applied to all cpus"

# reject <option> <value>: the value must be refused and nothing changed
reject() {
    local before after
    before=$("$SCRIPT" -read-all)
    if "$SCRIPT" "$1" "$2" 2> /dev/null; then
        echo "FAIL - $1 accepted '$2'"
        failures=$((failures + 1))
        return
    fi
    after=$("$SCRIPT" -read-all)
    if [ "$before" != "$after" ]; then
        echo "FAIL - rejected $1 '$2' still changed settings"
        failures=$((failures + 1))
        return
    fi
    echo "ok   - $1 rejects '$2'"
}

reject -cpu-min-perf ""
reject -cpu-min-perf 101
reject -cpu-max-perf "50 51"
reject -cpu-turbo yes
reject -gpu-max-freq -100
reject -cpu-governor "performance; reboot"
reject -cpu-governor "../../../etc/passwd"
reject -energy-perf balance
reject -thermal-mode "--help"
reject -lg-fan-mode 1
reject -powermizer 3
reject -powermizer "1 --assign=Foo=1"

# Settings of hardware that isn't there are left out
rm -r "$PLASMA_PSTATE_SYSFS/class/drm/card0" "$PLASMA_PSTATE_SYSFS/devices/platform/lg-laptop"
check "missing GPU is left out"        gpu_min_freq '<missing>'
check "missing LG laptop is left out"  lg_fan_mode '<missing>'
mv "$PLASMA_PSTATE_SYSFS/devices/system/cpu/intel_pstate" "$WORK/intel_pstate"
check "missing intel_pstate is left out" cpu_min_perf '<missing>'
check "missing turbo is left out"      cpu_turbo '<missing>'
mv "$WORK/intel_pstate" "$PLASMA_PSTATE_SYSFS/devices/system/cpu/intel_pstate"

# Like a missing GPU, whose directory is then /
rm "$PLASMA_PSTATE_SYSFS/devices/system/cpu/intel_pstate/max_perf_pct"
if "$SCRIPT" -cpu-max-perf 50 2> /dev/null || [ -e "$PLASMA_PSTATE_SYSFS/devices/system/cpu/intel_pstate/max_perf_pct" ]; then
    echo "FAIL - writing a missing setting"
    failures=$((failures + 1))
else
    echo "ok   - writing a missing setting fails and creates nothing"
fi
printf '100\n' > "$PLASMA_PSTATE_SYSFS/devices/system/cpu/intel_pstate/max_perf_pct"

chmod a-w "$PLASMA_PSTATE_SYSFS/devices/system/cpu/intel_pstate/max_perf_pct"
if "$SCRIPT" -cpu-max-perf 50 2> /dev/null; then
    echo "FAIL - failed write exits with 0"
    failures=$((failures + 1))
else
    echo "ok   - failed write exits with an error"
fi

if [ $failures -ne 0 ]; then
    echo "$failures failure(s)"
    exit 1
fi
echo "All tests passed"
