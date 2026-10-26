# Intel P-state and CPUFreq Manager Widget

Please don't use it any more. There is a maintained fork by frankenfruity at https://github.com/frankenfruity/plasma-pstate. 

If you are using Arch, AUR already points to the above repo.

Thank you @frankenfruity for taking over! :)



## Plasma 6

This version requires Plasma 6. Install it with `sudo ./install.sh`; it installs the widget system-wide
(`kpackagetool6 -g`) and adds the sudoers rule for `set_prefs.sh`.

It shows the settings your hardware has:

* intel_pstate's minimum and maximum performance, and turbo, which also works through the generic cpufreq
  boost and AMD's cpb
* the minimum and maximum frequency, for cpufreq drivers that list the frequencies they support
* the CPU governor, out of those the driver offers
* the Intel GPU's frequencies
* the energy performance preference
* Intel's Running Average Power Limits and Thermal Control Circuit offset
* Dell's thermal modes, the LG laptop driver's battery limit, USB charging and fan mode
* Nvidia's PowerMizer mode, and whether the Nvidia GPU is active or suspended

## Credits

Several of these, and the fixes to finding the Intel GPU and to keeping the Nvidia GPU idle, come from
[frankenfruity's fork](https://github.com/frankenfruity/plasma-pstate); the commits say which.

## Testing without an Intel CPU

`tests/` contains mocks that emulate an Intel laptop (with the Dell, LG and Nvidia extras), or a CPU without
intel_pstate (`MOCK_CPU=amd`), so the widget can be developed and tested on any machine:

* `tests/run-tests.sh` runs all tests: `test_set_prefs.sh` checks `set_prefs.sh`, `tst_backend.qml` checks
  reading and changing settings through the widget's backend, and `tst_utils.qml` has unit tests for the
  JavaScript helpers. The QML tests need `qmltestrunner` (from `qt6-declarative-dev-tools` on Debian).
* `tests/run-mock.sh` opens the widget in `plasmoidviewer` (from `plasma-sdk`) backed by the mocks, e.g.
  `tests/run-mock.sh -c org.kde.panel -f horizontal -l bottomedge` to see it in a panel.

The mocks work by setting `PLASMA_PSTATE_SYSFS` to the fake sysfs tree and putting stub `sudo`,
`smbios-thermal-ctl` and `nvidia-settings` commands first in `PATH`. `set_prefs.sh` ignores
`PLASMA_PSTATE_SYSFS` when running as root.
