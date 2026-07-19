#!/usr/bin/env bash
# Launch a marimo notebook in the background on the Tailscale IP, in two modes:
#   - edit mode: full browser editor                          (default port 2718)
#   - code mode: read-only app view with source code shown    (default port 2719)
# Both run with --watch (live-reload when the .py file is saved by an editor or
# an AI agent) and --no-token (no auth, so agents can talk to the server API).
#
# Usage: scripts/start-notebook.sh <notebook>.py [edit_port] [run_port]
set -euo pipefail

cd "$(dirname "$0")/.."

NOTEBOOK="${1:?usage: $0 <notebook>.py [edit_port] [run_port]}"
EDIT_PORT="${2:-2718}"
RUN_PORT="${3:-2719}"

# `tailscale ip -4` prints nothing under the snap install; read the interface instead
TS_IP=$(ip -4 -o addr show tailscale0 | awk '{print $4}' | cut -d/ -f1)
[ -n "$TS_IP" ] || { echo "error: no IPv4 address on tailscale0" >&2; exit 1; }

mkdir -p scratchpad

nohup uv run marimo edit --headless --host "$TS_IP" -p "$EDIT_PORT" \
    --watch --no-token "$NOTEBOOK" > scratchpad/marimo-edit.log 2>&1 &
echo "edit mode: http://$TS_IP:$EDIT_PORT (pid $!, log: scratchpad/marimo-edit.log)"

# code mode needs the file to exist already; edit mode above creates new ones
if [ -f "$NOTEBOOK" ]; then
    nohup uv run marimo run --headless --host "$TS_IP" -p "$RUN_PORT" \
        --watch --no-token --include-code "$NOTEBOOK" > scratchpad/marimo-run.log 2>&1 &
    echo "code mode: http://$TS_IP:$RUN_PORT (pid $!, log: scratchpad/marimo-run.log)"
else
    echo "code mode: skipped ($NOTEBOOK does not exist yet; save it in edit mode, then rerun)"
fi
