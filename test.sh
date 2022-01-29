#!/usr/bin/env bash

set -eu -o pipefail

echo
echo "Running tests"
echo "= = ="
echo

file=${1:-test/automated.zig}

(
  set -x;
  zig test --verbose-cimport --cache-dir ./zig-cache --pkg-begin log src/log.zig $file
)

echo
