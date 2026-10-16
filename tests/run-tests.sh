#!/bin/bash
# Run all tests against the mocks.

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

QMLTESTRUNNER=${QMLTESTRUNNER:-$(command -v qmltestrunner6 || command -v qmltestrunner || echo /usr/lib/qt6/bin/qmltestrunner)}

"$HERE/mock/setup.sh" "$WORK"
export PLASMA_PSTATE_SYSFS=$WORK/sys
export PATH=$HERE/mock/bin:$PATH
export QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-offscreen}

result=0
"$HERE/test_set_prefs.sh" || result=1
for test in "$HERE"/tst_*.qml; do
    "$QMLTESTRUNNER" -input "$test" || result=1
done
exit $result
