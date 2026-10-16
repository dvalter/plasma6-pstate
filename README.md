# Intel P-state and CPUFreq Manager Widget

Please don't use it any more. There is a maintained fork by frankenfruity at https://github.com/frankenfruity/plasma-pstate. 

If you are using Arch, AUR already points to the above repo.

Thank you @frankenfruity for taking over! :)



## Plasma 6

This version requires Plasma 6. Install it with `sudo ./install.sh`; it installs the widget system-wide
(`kpackagetool6 -g`) and adds the sudoers rule for `set_prefs.sh`.

## Testing without an Intel CPU

`tests/` contains mocks that emulate an Intel laptop (with the Dell, LG and Nvidia extras), so the widget
can be developed and tested on any machine:

* `tests/test_set_prefs.sh` checks `set_prefs.sh` against a fake sysfs tree.
* `qmltestrunner -input tests/tst_utils.qml` runs the JavaScript unit tests.
* `tests/run-mock.sh` opens the widget in `plasmoidviewer` (from `plasma-sdk`) backed by the mocks, e.g.
  `tests/run-mock.sh -c org.kde.panel -f horizontal -l bottomedge` to see it in a panel.

The mocks work by setting `PLASMA_PSTATE_SYSFS` to the fake sysfs tree and putting stub `sudo`,
`smbios-thermal-ctl` and `nvidia-settings` commands first in `PATH`. `set_prefs.sh` ignores
`PLASMA_PSTATE_SYSFS` when running as root.
