#!/usr/bin/env bash

set -e -o pipefail; [[ -n "$DEBUG" ]] && set -x

hugo_version="$1"

if [[ -z "$hugo_version" ]]; then
  echo "Usage: $0 <hugo-version>" >&2
  exit 1
fi

sed -i -e "s/HUGO_VERSION := .*$/HUGO_VERSION := $hugo_version/" Makefile
sed -i -e "s/HUGO_VERSION = .*$/HUGO_VERSION = \"$hugo_version\"/" netlify.toml
