#!/usr/bin/env bash

set -eu -o pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <library-name>"
  echo "e.g. $0 some-zig-library"
  exit 1
fi

echo
echo "Renaming Project"
echo "= = ="
echo

library_name=$1
echo "Library Name: $library_name"

constant=${library_name//-/_}
echo "Constant: $constant"

root_src=src/$constant.zig
echo "Root Source File: $root_src"

prompt=${PROMPT:-on}

echo
echo "If everything is correct, press return (Ctrl+c to abort; disable with PROMPT=off)"
if [ $prompt = "on" ]; then
  read -r
else
  echo "(skipped prompt; PROMPT is set to '$PROMPT')"
  echo
fi

echo "Renaming Files"
echo "- - -"

rename-file() {
  local path=$1
  local renamed_path=$2

  mkdir -vp $(dirname $renamed_path)
  mv -vf $path $renamed_path
}
rename-file "src/template.zig" $root_src

echo
echo "Replacing Tokens"
echo "- - -"

replace-token() {
  local token=$1
  local replacement=$2

  files=($(grep -rl "$token" . | grep -v $(basename $0)))

  if [ -n "${files[*]}" ]; then
    echo "Substituting $token with $replacement (Files: ${files[@]})"
    xargs sed -i "s/$token/${replacement//\//\\/}/g" <<<${files[@]}
  fi
}
replace-token "TEMPLATE_LIBRARY" $library_name
replace-token "TEMPLATE_ROOT_SRC" $root_src
replace-token "TEMPLATE_CONST" $constant

echo
echo "Deleting Template Artifacts"
echo "- - -"
echo

rm -vf rename.sh restore-template.sh

echo
echo "(done)"
