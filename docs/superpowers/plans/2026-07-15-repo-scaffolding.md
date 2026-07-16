# Repo Scaffolding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold `xpectral-research` as a notebook-driven quant/data-science research repo: `uv`-managed environment, ruff linting, a notebook naming convention, and a starter notebook that smoke-tests the environment.

**Architecture:** No installable package (`src/`) — notebooks import directly from installed libraries. `pyproject.toml` is a dependency-only manifest (`[tool.uv] package = false`) managed via `uv sync`, with `uv.lock` committed for reproducibility. Notebooks live flat in `notebooks/`, numbered `NNN_description.ipynb`.

**Tech Stack:** `uv` (env/dependency manager), `jupyterlab` + `ipykernel` (notebooks), `numpy`/`pandas`/`matplotlib` (baseline research stack), `ruff` (lint/format).

## Global Constraints

- Python version: `3.12` (from `.python-version`).
- No `src/` package, no `tests/`, no CI, no `data/` directory — explicitly out of scope per spec.
- Every notebook's first cell must be exactly:
  ```python
  %load_ext autoreload
  %autoreload 2
  ```
  (per user's global CLAUDE.md notebook rule).
- Dependency management via `uv sync` (not bare `uv pip install`); `uv.lock` is committed.
- `.gitignore` must cover: `.venv/`, `__pycache__/`, `.ipynb_checkpoints/`, `.ruff_cache/`, `.DS_Store`.
- Commit messages: no capital letters (except inherently-capitalized identifiers), per user's global CLAUDE.md.

Spec: `docs/superpowers/specs/2026-07-15-repo-scaffolding-design.md`

---

### Task 1: Environment, dependencies, and lint config

**Files:**
- Create: `xpectral-research/.python-version`
- Create: `xpectral-research/pyproject.toml`
- Create: `xpectral-research/.gitignore`

**Interfaces:**
- Produces: a working `.venv` at `xpectral-research/.venv`, a committed `uv.lock`, and a `uv run <cmd>` entrypoint usable by later tasks (`uv run jupyter nbconvert ...`, `uv run ruff check .`).

- [ ] **Step 1: Create `.python-version`**

File: `xpectral-research/.python-version`
```
3.12
```

- [ ] **Step 2: Create `.gitignore`**

File: `xpectral-research/.gitignore`
```
.venv/
__pycache__/
.ipynb_checkpoints/
.ruff_cache/
.DS_Store
```

- [ ] **Step 3: Create `pyproject.toml`**

File: `xpectral-research/pyproject.toml`
```toml
[project]
name = "xpectral-research"
version = "0.1.0"
description = "Notebook-driven quant/data-science research"
requires-python = ">=3.12"
dependencies = [
    "jupyterlab>=4.0",
    "ipykernel>=6.0",
    "numpy>=1.26",
    "pandas>=2.2",
    "matplotlib>=3.8",
]

[tool.uv]
package = false

[tool.ruff]
line-length = 88
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "W", "I"]
```

`[tool.uv] package = false` tells `uv` this is a dependency manifest only — no `src/` build target, so `uv sync` won't try to build/install a local package that doesn't exist.

- [ ] **Step 4: Run `uv sync` and verify it succeeds**

Run (from `xpectral-research/`):
```bash
uv sync
```
Expected: exits 0, creates `.venv/` and `uv.lock`, output ends with something like `Installed N packages`.

- [ ] **Step 5: Verify the lockfile and venv exist**

Run:
```bash
test -f uv.lock && test -d .venv && echo OK
```
Expected: prints `OK`.

- [ ] **Step 6: Commit**

```bash
git add .python-version .gitignore pyproject.toml uv.lock
git commit -m "$(cat <<'EOF'
add uv-managed environment and ruff config

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: README

**Files:**
- Create: `xpectral-research/README.md`

**Interfaces:**
- Consumes: the `uv sync` workflow established in Task 1 (documents it, doesn't change it).

- [ ] **Step 1: Create `README.md`**

File: `xpectral-research/README.md`
```markdown
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
```

- [ ] **Step 2: Verify the file renders sane markdown (visual check)**

Run:
```bash
cat README.md
```
Expected: readable markdown, no broken fences (the outer code block above is illustrative for this plan only — the actual file must not be wrapped in an extra fence).

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
add readme with setup and notebook convention

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Starter notebook

**Files:**
- Create: `xpectral-research/notebooks/001_setup_check.ipynb`

**Interfaces:**
- Consumes: the `.venv` and dependencies from Task 1 (`jupyterlab`, `ipykernel`, `numpy`, `pandas`, `matplotlib`).

- [ ] **Step 1: Create the notebook**

File: `xpectral-research/notebooks/001_setup_check.ipynb`
```json
{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "%load_ext autoreload\n",
    "%autoreload 2"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import matplotlib\n",
    "import numpy as np\n",
    "import pandas as pd\n",
    "\n",
    "print(f\"numpy: {np.__version__}\")\n",
    "print(f\"pandas: {pd.__version__}\")\n",
    "print(f\"matplotlib: {matplotlib.__version__}\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "name": "python",
   "version": "3.12"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
```

- [ ] **Step 2: Execute the notebook out-of-place to verify it runs clean**

Run (from `xpectral-research/`):
```bash
uv run jupyter nbconvert --to notebook --execute notebooks/001_setup_check.ipynb \
  --output-dir /private/tmp/claude-501/-Users-danieltrivino-Desktop-github-xpectral-research/fb32a351-12db-4506-9c5a-171de012abfb/scratchpad
```
Expected: exits 0, no traceback in stderr. If a cell errors, `nbconvert` prints the traceback and exits non-zero.

- [ ] **Step 3: Confirm the printed versions landed in the executed output**

Run:
```bash
grep -E "numpy:|pandas:|matplotlib:" /private/tmp/claude-501/-Users-danieltrivino-Desktop-github-xpectral-research/fb32a351-12db-4506-9c5a-171de012abfb/scratchpad/001_setup_check.ipynb
```
Expected: three lines of JSON-escaped output text containing `numpy: `, `pandas: `, `matplotlib: ` followed by version strings.

- [ ] **Step 4: Lint the notebook**

Run:
```bash
uv run ruff check notebooks/001_setup_check.ipynb
```
Expected: `All checks passed!`

- [ ] **Step 5: Commit**

```bash
git add notebooks/001_setup_check.ipynb
git commit -m "$(cat <<'EOF'
add starter notebook that smoke-tests the environment

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Post-plan verification

- [ ] From a clean clone (or after `rm -rf .venv uv.lock && uv sync`), confirm `uv sync` → `jupyter lab` → running `001_setup_check.ipynb` top-to-bottom works end to end, matching the spec's success criteria.
