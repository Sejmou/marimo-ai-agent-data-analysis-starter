# marimo notebook AI agent assisted data analysis starter
This basic repo contains all the core things an AI agent needs to help a human do basic data analysis in a notebook

## Setup
This uses `uv` for Python package management (waaaaaaay faster, easier and more robust than the old school pip + requirements.txt/pyproject.toml way)

Make sure you have `uv` installed.

Then, inside the repo root, run

```bash
uv sync
```

This installs the core packages this starter project ships, specifically:
- `marimo`: modern replacement for Jupyter; way faster and more optimized for working with AI
- `polars` and `duckdb`: essential for any type of quick data analysis (way faster than pandas, too)
- `ruff`: code formatting
- `python-lsp-server`: enables things like `F2 for rename`

## Launching a notebook session (creates new notebook if doesn't exist; edits existing one if it does)
The standard way to launch is in the background, bound to this machine's Tailscale IP, in **two modes on two separate ports**:

- **edit mode** (`marimo edit`, port 2718): the full browser editor
- **code mode** (`marimo run --include-code`, port 2719): the read-only app view with the source code visible

Both run with `--watch` (the server live-reloads when the `.py` file is saved by another editor or an AI agent) and `--no-token` (no auth, so agents can interact with the notebook server API).

```bash
scripts/start-notebook.sh <notebook_name>.py
```

This prints both URLs and PIDs, and writes logs to `scratchpad/marimo-edit.log` and `scratchpad/marimo-run.log`. Custom ports: `scripts/start-notebook.sh <notebook>.py <edit_port> <run_port>`.

What the script does, spelled out (in case you need to run it by hand):

```bash
# `tailscale ip -4` prints nothing under the snap install, so read the interface:
TS_IP=$(ip -4 -o addr show tailscale0 | awk '{print $4}' | cut -d/ -f1)

nohup uv run marimo edit --headless --host "$TS_IP" -p 2718 \
    --watch --no-token <notebook_name>.py > scratchpad/marimo-edit.log 2>&1 &

nohup uv run marimo run --headless --host "$TS_IP" -p 2719 \
    --watch --no-token --include-code <notebook_name>.py > scratchpad/marimo-run.log 2>&1 &
```

Notes:
- `--headless` is required in the background, otherwise marimo tries to open a browser.
- Code mode (`marimo run`) needs the notebook file to exist already; edit mode creates new ones. For a brand-new notebook, the script skips code mode — save the notebook once in edit mode, then rerun the script.
- With an explicit `-p`, marimo does *not* hunt for a free port, so stop old servers before relaunching: `pkill -f 'marimo edit'; pkill -f 'marimo run'`
- Agents should talk to the **edit-mode** server (`http://$TS_IP:2718`) — that's the one whose API the `marimo-pair` skill uses.
- `--no-token` means anyone on the tailnet can execute code via these servers; that's the intended agent-friendly setup here, but don't bind them to a public interface.

## Make edits to the notebook via `marimo-pair`
This repo contains a copy of the `marimo-pair` agent skill. It contains instructions on how to discover marimo servers and execute code within notebooks (to inspect their state and edit cells as needed), including dedicated bash scripts for the agent to run.

Usually, running `discovers-servers.sh` is a total waste of time/tokens (and may result in permissions issues) if the agent already knows what the server it should talk to (e.g. as it was told so by its human).

Finally, `execute-code.sh` also sometimes results in issues if the agent uses special characters that don't work nicely with heredoc syntax. Therefore, a `scratchpad` directory is also setup for throwaway python code to be inserted into the notebook by reading the code from a file on the filesystem directly.
