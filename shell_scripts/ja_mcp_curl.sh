#!/usr/bin/env bash
# Check an MCP HTTP endpoint and list its advertised capabilities.
# Author: S M Jahangir Alam <jahangir2526@gmail.com>
# Last updated: 2026-08-29 13:26:57 +08

set -euo pipefail

protocol_version="2025-03-26"

usage() {
  cat <<EOF
Usage: ${0##*/} <mcp-http-url> <check|tl|pl|rtl|rl|all>

  check  initialize the server and report its identity and capabilities
  tl     list tools
  pl     list prompts
  rtl    list resource templates
  rl     list resources
  all    list every capability advertised by the server

Example:
  ${0##*/} https://gateway.mcpservers.org/yahoo-finance/mcp check
  ${0##*/} https://gateway.mcpservers.org/yahoo-finance/mcp all
EOF
}

if [[ $# -ne 2 ]]; then
  usage >&2
  exit 2
fi

for command in curl jq; do
  command -v "$command" >/dev/null || {
    printf 'Required command not found: %s\n' "$command" >&2
    exit 127
  }
done

url=$1
action=$2
case "$action" in check|tl|pl|rtl|rl|all) ;; *) usage >&2; exit 2 ;; esac

headers_file=$(mktemp)
trap 'rm -f "$headers_file"' EXIT

# MCP responses may be JSON or Server-Sent Events. Extract JSON from either.
mcp_json() {
  local response
  response=$(cat)
  if [[ "$response" == *"data: "* ]]; then
    printf '%s\n' "$response" | sed -n 's/^data: //p'
  else
    printf '%s\n' "$response"
  fi
}

initialize_response=$(curl --silent --show-error --fail-with-body \
  --dump-header "$headers_file" \
  --request POST "$url" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json, text/event-stream' \
  --data '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"ja-mcp-curl","version":"1.0"}}}')

initialize_json=$(printf '%s\n' "$initialize_response" | mcp_json)
if ! printf '%s\n' "$initialize_json" | jq -e '.result' >/dev/null; then
  printf 'MCP initialization failed:\n%s\n' "$initialize_json" >&2
  exit 1
fi

protocol_version=$(printf '%s\n' "$initialize_json" | jq -r '.result.protocolVersion // "2025-03-26"')
session=$(awk 'BEGIN { IGNORECASE=1 } /^mcp-session-id:/ { print $2 }' "$headers_file" | tr -d '\r')

server_name=$(printf '%s\n' "$initialize_json" | jq -r '.result.serverInfo.name // "unknown"')
server_version=$(printf '%s\n' "$initialize_json" | jq -r '.result.serverInfo.version // "unknown"')
printf 'MCP server: %s (version %s)\nProtocol: %s\n' "$server_name" "$server_version" "$protocol_version"
[[ -n "$session" ]] && printf 'Session: %s\n' "$session" || printf 'Session: stateless (no Mcp-Session-Id supplied)\n'

mcp_post() {
  local id=$1 method=$2
  local -a headers=(
    --header 'Content-Type: application/json'
    --header 'Accept: application/json, text/event-stream'
    --header "MCP-Protocol-Version: $protocol_version"
  )
  [[ -n "$session" ]] && headers+=(--header "Mcp-Session-Id: $session")

  curl --silent --show-error --fail-with-body --request POST "$url" "${headers[@]}" \
    --data "{\"jsonrpc\":\"2.0\",\"id\":$id,\"method\":\"$method\",\"params\":{}}"
}

list() {
  local id=$1 method=$2 result_key=$3
  local response json
  response=$(mcp_post "$id" "$method")
  json=$(printf '%s\n' "$response" | mcp_json)
  if ! printf '%s\n' "$json" | jq -e '.result' >/dev/null; then
    printf '\n%s is unavailable:\n%s\n' "$method" "$json" >&2
    return 1
  fi
  printf '\n=== %s ===\n' "$method"
  printf '%s\n' "$json" | jq ".result.$result_key[]? | {name, description}"
}

has_capability() {
  local capability=$1
  printf '%s\n' "$initialize_json" | jq -e ".result.capabilities.$capability != null" >/dev/null
}

list_if_advertised() {
  local capability=$1 id=$2 method=$3 result_key=$4
  if has_capability "$capability"; then
    list "$id" "$method" "$result_key"
  else
    printf '\n=== %s ===\nNot advertised by this server.\n' "$method"
  fi
}

case "$action" in
  check)
    printf 'Capabilities: '
    printf '%s\n' "$initialize_json" | jq -r '[.result.capabilities | keys[]] | join(", ")'
    ;;
  tl) list_if_advertised tools 2 tools/list tools ;;
  pl) list_if_advertised prompts 3 prompts/list prompts ;;
  rtl) list_if_advertised resources 4 resources/templates/list resourceTemplates ;;
  rl) list_if_advertised resources 5 resources/list resources ;;
  all)
    list_if_advertised tools 2 tools/list tools
    list_if_advertised prompts 3 prompts/list prompts
    list_if_advertised resources 4 resources/templates/list resourceTemplates
    list_if_advertised resources 5 resources/list resources
    ;;
esac
