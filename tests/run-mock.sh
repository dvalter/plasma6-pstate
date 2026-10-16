#!/bin/bash
# Run the widget in plasmoidviewer (from plasma-sdk) against the mock sysfs
# tree and mock vendor tools. Extra arguments go to plasmoidviewer.

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

"$HERE/mock/setup.sh" "$WORK"
export PLASMA_PSTATE_SYSFS=$WORK/sys
export PATH=$HERE/mock/bin:$PATH

plasmoidviewer -a "$HERE/../gr.ictpro.jsalatas.plasma.pstate" "$@"
