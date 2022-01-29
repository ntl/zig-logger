#!/usr/bin/env bash

set -eu -o pipefail

echo
echo "Compiling"
echo "= = ="
echo

clean=${CLEAN:-on}
echo "CLEAN: ${CLEAN:-$clean (default)}"
echo

if [ $clean = "on" ]; then
  (set -x; git clean --force -d -X)
fi

(
  set -x;
  zig build update-formatting test install
)

echo
