# xpectral-research

Notebook-driven quant/data-science research.

## Setup

```bash
uv sync
source .venv/bin/activate
```

## Running notebooks

```bash
jupyter lab
```

## Notebook convention

Notebooks live flat in `notebooks/`, named `NNN_description.ipynb` (e.g.
`001_setup_check.ipynb`, `002_signal_x.ipynb`). Every notebook's first cell
must be:

```python
%load_ext autoreload
%autoreload 2
```

## Linting

```bash
uv run ruff check .
uv run ruff format .
```
