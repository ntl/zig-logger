#!/usr/bin/env bash

set -eu -o pipefail

echo
echo "Restoring Template"
echo "= = ="
echo

git clean -d --force
git restore .

echo "- - -"
echo "(done)"
echo
