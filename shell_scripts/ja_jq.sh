#!/usr/bin/env bash
#
# Author: S M Jahangir Alam <jahangir2526@gmail.com>
# Last updated: 2026-08-29 13:26:57 +08
#
# jqpick.sh - interactively select and print a value from JSON on macOS.
#
# Usage:
#   your-command | ./jqpick.sh
#   your-command | ./jqpick.sh --glow
#   your-command | ./jqpick.sh | glow -
#
# In jless, navigate to the desired value, press "yq" (not "pq") to copy its
# jq-style path to the macOS clipboard, then press "q" to quit. This script
# applies that path with jq -r.

set -o nounset
set -o pipefail

program_name=${0##*/}
render_with_glow=false
tmp_file=
result_file=

usage() {
    cat >&2 <<EOF
Usage: your-command | $program_name [--glow]

Options:
  -g, --glow  Render the selected value as Markdown with glow.
  -h, --help  Show this help.

Without --glow, the selected value is printed with jq -r and can be piped
to another command, for example: your-command | $program_name | glow -
EOF
}

while (( $# > 0 )); do
    case $1 in
        -g|--glow)
            render_with_glow=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            printf '%s: unknown option: %s\n' "$program_name" "$1" >&2
            usage
            exit 2
            ;;
    esac
    shift
done

if (( $# > 0 )); then
    printf '%s: unexpected argument: %s\n' "$program_name" "$1" >&2
    usage
    exit 2
fi

for dependency in jless jq pbpaste; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf '%s: required command not found: %s\n' "$program_name" "$dependency" >&2
        exit 127
    fi
done

if [[ "$render_with_glow" == true ]] && ! command -v glow >/dev/null 2>&1; then
    printf '%s: --glow requires the command: glow\n' "$program_name" >&2
    exit 127
fi

# Check for a controlling terminal before consuming the entire input stream.
if ! { : </dev/tty; } 2>/dev/null; then
    printf '%s: an interactive terminal is required to run jless\n' "$program_name" >&2
    exit 2
fi

tmp_file=$(mktemp "${TMPDIR:-/tmp}/jqpick.XXXXXX") || {
    printf '%s: could not create a temporary file\n' "$program_name" >&2
    exit 1
}
cleanup() {
    [[ -z "$tmp_file" ]] || rm -f -- "$tmp_file"
    [[ -z "$result_file" ]] || rm -f -- "$result_file"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ -t 0 ]]; then
    usage
    exit 2
fi

cat >"$tmp_file" || {
    printf '%s: failed to read JSON from standard input\n' "$program_name" >&2
    exit 1
}

if [[ ! -s "$tmp_file" ]]; then
    printf '%s: standard input was empty\n' "$program_name" >&2
    exit 2
fi

if ! jq empty "$tmp_file" >/dev/null; then
    printf '%s: standard input is not valid JSON\n' "$program_name" >&2
    exit 2
fi

printf '%s\n' 'Navigate to a value, press yq to copy its jq path, then press q to quit.' >&2
# stdin may be the JSON pipeline and stdout may be another pipeline, so connect
# jless input to the terminal. Redirect its display only when stdout is piped,
# keeping the final extracted value as the script's sole pipeline output.
if [[ -t 1 ]]; then
    jless "$tmp_file" </dev/tty
else
    jless "$tmp_file" </dev/tty >/dev/tty
fi
status=$?
if (( status != 0 )); then
    printf '%s: jless exited with status %d\n' "$program_name" "$status" >&2
    exit "$status"
fi

jq_path=$(pbpaste 2>/dev/null) || {
    printf '%s: could not read the macOS clipboard with pbpaste\n' "$program_name" >&2
    exit 1
}

if [[ -z "$jq_path" ]]; then
    printf '%s: the clipboard is empty; press yq in jless before quitting\n' "$program_name" >&2
    exit 2
fi

if (( ${#jq_path} > 16384 )); then
    printf '%s: clipboard jq path is unexpectedly long\n' "$program_name" >&2
    exit 2
fi

if [[ "$jq_path" != .* || "$jq_path" =~ [[:cntrl:]] ]]; then
    printf '%s: clipboard does not contain a single jq path beginning with a dot: %q\n' \
        "$program_name" "$jq_path" >&2
    printf '%s\n' 'In jless, use yq to copy the path; pq only prints it.' >&2
    exit 2
fi

result_file=$(mktemp "${TMPDIR:-/tmp}/jqpick-result.XXXXXX") || {
    printf '%s: could not create a temporary result file\n' "$program_name" >&2
    exit 1
}

# Extract once into a temporary result. This validates the copied filter and
# avoids leaking partial output if jq fails partway through processing it.
if ! jq -r "$jq_path" "$tmp_file" >"$result_file"; then
    printf '%s: clipboard does not contain a valid/matching jq path: %q\n' \
        "$program_name" "$jq_path" >&2
    printf '%s\n' 'In jless, use yq to copy the path; pq only prints it.' >&2
    exit 2
fi

if [[ "$render_with_glow" == true ]]; then
    printf 'jq -r %q | glow -\n' "$jq_path" >&2
    glow - <"$result_file"
else
    printf 'jq -r %q\n' "$jq_path" >&2
    cat "$result_file"
fi
