#!/usr/bin/env bash

set -e -o pipefail; [[ -n "$DEBUG" ]] && set -x

SCRIPT_ROOT="$(cd "$(dirname "$0")"; pwd)"
HUGO=("${HUGO:-hugo}")

yymmdd="$(date +%y%m%d)"; \
content_file="content/${yymmdd}-<title>.md"
echo -n "$content_file: "
read title
content_file="$(echo "$content_file" | sed -e "s/<title>/$title/")"
"${HUGO[@]}" new "$content_file"
$EDITOR "${SCRIPT_ROOT}/../${content_file}"
# vim: ai ts=2 sw=2 et sts=2 ft=sh
