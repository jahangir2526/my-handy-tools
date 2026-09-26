# Shell scripts

Small Bash utilities for macOS and Unix-like terminals. Run the examples from
the repository root. If a script is not executable, invoke it with `bash` or
make it executable once:

```bash
chmod +x shell_scripts/*.sh
```

## `ja_compare_strings.sh`

Compares two strings and prints `EQUAL` or `NOT EQUAL`.

```bash
shell_scripts/ja_compare_strings.sh "hello" "hello"
# EQUAL

shell_scripts/ja_compare_strings.sh "hello" "world"
# NOT EQUAL
```

Quote values containing spaces or shell-special characters.

## `ja_git_push_changes.sh`

Stages all current changes, creates a commit, pulls the selected remote branch,
and pushes to it. It displays a macOS confirmation dialog before pushing to
`main`.

```bash
shell_scripts/ja_git_push_changes.sh "Add request validation" "feature/validation"
```

Requirements: Git, a configured `origin` remote, and a branch name that can be
pulled from and pushed to. Review `git status` first: the script uses `git add
.` and therefore stages every changed and untracked file in the repository.

## `ja_jq.sh`

Interactively chooses a value from JSON. The script opens `jless`; navigate to
the desired value, press `yq` to copy its jq path to the macOS clipboard, then
press `q`. The selected value is printed to standard output.

```bash
curl -s https://api.github.com/repos/jqlang/jq | shell_scripts/ja_jq.sh

kubectl get pods -o json | shell_scripts/ja_jq.sh

cat response.json | shell_scripts/ja_jq.sh | glow -
```

Use `--glow` (or `-g`) to render the selected value directly as Markdown:

```bash
cat README.json | shell_scripts/ja_jq.sh --glow
```

Requirements: `jq`, `jless`, `pbpaste`, and an interactive terminal. `glow` is
also required when using `--glow`.

## `ja_latency_test_mac.sh`

Sends a GET request and prints curl timing phases, including DNS lookup,
connection, TLS, time to first byte, and total time.

```bash
shell_scripts/ja_latency_test_mac.sh --url https://example.com

shell_scripts/ja_latency_test_mac.sh -u https://api.github.com
```

Requirement: `curl`. If no URL is provided, the script reports that the target
URL was not specified.

## `ja_mcp_curl.sh`

Initializes an MCP HTTP server and inspects its advertised capabilities.

```bash
shell_scripts/ja_mcp_curl.sh https://gateway.mcpservers.org/yahoo-finance/mcp check

shell_scripts/ja_mcp_curl.sh https://gateway.mcpservers.org/yahoo-finance/mcp tl

shell_scripts/ja_mcp_curl.sh https://gateway.mcpservers.org/yahoo-finance/mcp all
```

The second argument selects what to inspect:

| Value | Action |
| --- | --- |
| `check` | Show server identity, protocol version, and capabilities. |
| `tl` | List tools. |
| `pl` | List prompts. |
| `rtl` | List resource templates. |
| `rl` | List resources. |
| `all` | List all advertised items. |

Requirements: `curl`, `jq`, and network access to the MCP endpoint.

## `ja_shell_arguments_test.sh`

Displays common Bash positional-parameter variables. Useful for learning how a
script receives its arguments.

```bash
shell_scripts/ja_shell_arguments_test.sh first "second value" third
```

It prints `$0`, the first three arguments (`$1`–`$3`), all arguments (`$*`),
and the previous command status (`$?`).

## `ja_which_copy.sh`

Prints the absolute path for a supplied file and copies that path to the macOS
clipboard.

```bash
shell_scripts/ja_which_copy.sh shell_scripts/README.md

pbpaste
```

Requirement: macOS `pbcopy`. The input may be relative or absolute; its parent
directory must exist.

## `smart_web_utilities.html`

A standalone browser-based workbench for common text, data, and productivity
tasks. Open it directly in a modern browser; no build or local server is
required.

```bash
open smart_web_utilities.html
```

Available tools:

| Tool | What it does |
| --- | --- |
| Text Editor | Create, rename, delete, copy, and save plain-text documents. |
| JSON/YAML Editor | Validate, format, minify JSON, convert between JSON and YAML, and inspect output as code, a tree, cards, a form, or plain text. |
| Generator | Create passwords, SHA-256/384/512 hashes, Base64 values, URL-encoded text, and downloadable QR-code PNGs. |
| Timer/Stopwatch | Run a countdown or stopwatch, add quick time increments, record laps, control sound, and use fullscreen mode. |
| Calculator | Perform basic arithmetic with on-screen controls or the keyboard, and convert whole numbers between binary, octal, decimal, and hexadecimal. |

Example JSON workflow:

1. Open the **JSON/YAML Editor** tab.
2. Paste `{"name":"Ada","roles":["admin","editor"]}`.
3. Select **Format** to pretty-print it, or **Convert to YAML** to produce YAML.
4. Choose an output view, then use **Copy** to copy the result.

Text documents, editor preferences, and the selected workspace are stored in
the browser's local storage. Core processing happens locally in the browser.
The QR-code generator loads its QR library from cdnjs, so that feature needs
network access when the library is not already cached.
