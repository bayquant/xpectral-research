# Contributing

See `CLAUDE.md` for the notebook and project naming convention.

## Working on xpectral-quant / xpectral-chart locally

If you're making changes to a local checkout of `xpectral-quant` or
`xpectral-chart` (expected at `../xpectral-quant` and `../xpectral-chart`)
and want this repo to pick them up, install them into the venv directly
instead of editing `pyproject.toml`:

```bash
uv pip install -e ../xpectral-quant -e ../xpectral-chart
```

This keeps `pyproject.toml` and `uv.lock` pointed at the published versions
for everyone else. The editable install only affects your local venv, so a
future `uv sync` will remove it again — reinstall with the command above
whenever that happens.
