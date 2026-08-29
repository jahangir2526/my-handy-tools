# Handy Shell Scripts

Small command-line helpers in [`shell_scripts/`](shell_scripts).

| Script | Usage | Purpose |
| --- | --- | --- |
| `ja_shell_arguments_test.sh` | `./shell_scripts/ja_shell_arguments_test.sh one two three` | Prints common shell argument and status variables. |
| `ja_compare_strings.sh` | `./shell_scripts/ja_compare_strings.sh "one" "two"` | Reports whether two strings are equal. |
| `ja_mcp_curl.sh` | `./shell_scripts/ja_mcp_curl.sh https://gateway.mcpservers.org/yahoo-finance/mcp check` | Checks an MCP server or lists its advertised tools, prompts, and resources. Requires `curl` and `jq`. |
| `ja_jq.sh` | `some-json-command | ./shell_scripts/ja_jq.sh` | Interactively selects a JSON value with `jless`, then prints it using `jq`. macOS only; requires `jless`, `jq`, and `pbpaste` (optional `glow` via `--glow`). |
| `ja_latency_test_mac.sh` | `./shell_scripts/ja_latency_test_mac.sh --url https://example.com` | Shows curl DNS, connection, transfer, and total request timing. |
| `ja_git_push_changes.sh` | `./shell_scripts/ja_git_push_changes.sh "commit message"` | Stages all changes, commits them, pulls, and pushes `main`. Review changes first. |

Run a script with `bash <script>` if it is not executable. Scripts that contact a service or Git remote require the relevant network access and credentials.
