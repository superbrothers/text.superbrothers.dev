#!/usr/bin/env bash

set -e -o pipefail; [[ -n "$DEBUG" ]] && set -x

SCRIPT_ROOT="$(cd "$(dirname "$0")"; pwd)"

CONTENT_DIR="${SCRIPT_ROOT}/../content"
OGP_DIR="${SCRIPT_ROOT}/../static/ogp"
mkdir -p "${OGP_DIR}"

if ! command -v pageres >/dev/null; then
  echo "Require 'pageres' command to run this script" >&2
  echo "https://github.com/sindresorhus/pageres-cli" >&2
  exit 1
fi

function generate-ogp-image() {
  local content_file url

  content_file="$1"

  content_name="$(basename "${content_file%.*}")"
  if [[ -f "${content_name}.png" ]]; then
    echo "Skip generating ${content_name}.png because it already exists"
    return
  fi

  echo "Generating ${content_name}.png"

  if [[ "$content_name" =~ \.en$ ]]; then
    url="http://localhost:8080/en/${content_name%.*}"
  else
    url="http://localhost:8080/${content_name}"
  fi
  pageres \
    "$url" \
    1200x630 \
    --crop \
    --filename="$content_name" \
    --delay=5 \
    --css='#content { max-width: none; } html { font-size: 1.5em; }'
}
export -f generate-ogp-image

make -C "${SCRIPT_ROOT}/.." serve-without-watch &
PID="$!"
function on-exit() {
  kill "$PID"
  cd "${SCRIPT_ROOT}/.."
  rm -rf .hugo_build.lock resources
}
trap on-exit EXIT

# wait for serving pages
while true; do
  if [[ "$(curl "localhost:8080" -o /dev/null -w '%{http_code}\n' -s)" == "200" ]]; then
    break
  fi
  sleep 1
done

cd "${OGP_DIR}"
find "${CONTENT_DIR}" -name "*.md" | xargs -I{} -P 5 bash -c 'generate-ogp-image {}'
# vim: ai ts=2 sw=2 et sts=2 ft=sh
