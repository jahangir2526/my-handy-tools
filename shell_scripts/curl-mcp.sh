#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "==============================================="
    echo "Usage: $0 <mcp-http-url> <tl|rl|pl|all>"
    echo "==============================================="
    echo "  tl  -> tools/list"
    echo "  pl  -> prompts/list"
    echo "  rtl -> resources/templates/list"
    echo "  rl  -> resources/list"
    echo "  all -> runs for all tools, prompts and resources templates and resources" 
    echo "==============================================="
    echo "Example:"
    echo "  $0 http://localhost:8000/mcp tl"
    echo "  $0 http://localhost:8000/mcp all"
    echo "==============================================="
    exit 1
fi

URL="$1"
LIST_TYPE="$2"

echo
echo "Initializing MCP session..."
echo 

INIT_RESPONSE=$(curl -si -X POST "$URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"initialize",
    "params":{
      "protocolVersion":"2025-03-26",
      "capabilities":{},
      "clientInfo":{
        "name":"curl",
        "version":"1.0"
      }
    }
  }')

SESSION=$(echo "$INIT_RESPONSE" | awk '/^mcp-session-id:/ {print $2}' | tr -d '\r')

if [ -z "$SESSION" ]; then
    echo "Failed to obtain Mcp-Session-Id"
    echo
    echo "$INIT_RESPONSE"
    exit 1
fi

echo "Session: $SESSION"
echo

curl -s -X POST "$URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "Mcp-Session-Id: $SESSION" \
  -d '{
    "jsonrpc":"2.0",
    "method":"notifications/initialized"
  }' >/dev/null

call() {
  local id=$1
  local method=$2
  local filter=$3

  echo
  echo "=== Available $method ==="

  curl -s -X POST "$URL" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -H "Mcp-Session-Id: $SESSION" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":$id,\"method\":\"$method\"}" | jq ".result.$filter[] | {name, description}"
}

list_tools() {
  call 2 tools/list tools
}

list_prompts() {
  call 3 prompts/list prompts
}

list_resources_templates() {
  call 4 resources/templates/list resourceTemplates
}

list_resources() {
  call 5 resources/list resources
}


case "$LIST_TYPE" in
  tl)
    list_tools
    ;;
  rl)
    list_prompts
    ;;
  rtl)
    list_resources_templates
    ;;
  pl)
    list_resources
    ;;
  all)
    list_tools
    list_prompts
    list_resources_templates
    list_resources
    ;;
  *)
    echo "Invalid list type: $LIST_TYPE"
    echo "Expected one of: tl, pl, rtl, rl, all"
    exit 1
    ;;
esac
