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
In a separate long-running shell, run

```bash
uv run marimo edit --watch --no-token <notebook_name>.py
```
Per default, this runs on localhost:2718, incrementing the port number one-by-one until a free one becomes available if the current is already taken

## Make edits to the notebook via `marimo-pair`
This repo contains a copy of the `marimo-pair` agent skill. It contains instructions on how to discover marimo servers and execute code within notebooks (to inspect their state and edit cells as needed), including dedicated bash scripts for the agent to run.

Usually, running `discovers-servers.sh` is a total waste of time/tokens (and may result in permissions issues) if the agent already knows what the server it should talk to (e.g. as it was told so by its human).

Finally, `execute-code.sh` also sometimes results in issues if the agent uses special characters that don't work nicely with heredoc syntax. Therefore, a `scratchpad` directory is also setup for throwaway python code to be inserted into the notebook by reading the code from a file on the filesystem directly.
