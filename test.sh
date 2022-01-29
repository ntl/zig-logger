#!/usr/bin/env bash

set -eu -o pipefail

echo
echo "Running tests"
echo "= = ="
echo

file=${1:-test/automated.zig}

(
  set -x;
  zig test --cache-dir ./zig-cache --pkg-begin TEMPLATE_LIBRARY TEMPLATE_ROOT_SRC $file
)

echo
