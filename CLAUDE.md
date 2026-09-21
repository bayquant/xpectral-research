# CLAUDE.md

## Naming Convention and Organization

### Sequence Numbering

Everything in `research/` shares a single sequence number, whether it's a
standalone notebook or a folder of resources:

```
research/nnn_slug.ipynb    # standalone notebook, no supporting resources
research/nnn_slug/         # project folder, when resources are needed
```

Numbers are unique across both forms and assigned in chronological order.
Don't reuse or reorder them.

### Inside a Project Folder

Use a fixed entry-point notebook name (`analysis.ipynb`), not the slug again,
and organize supporting resources into generic subfolders as needed:

```
research/nnn_slug/
├── analysis.ipynb   # entry point (or a notebooks/ folder, see below)
├── report/          # optional typst paper and its resources (report.typ, references.bib, ...)
├── data/            # raw or processed datasets (csv, parquet, etc.)
├── assets/          # reference material: papers, PDFs, images, slides
├── scripts/         # standalone .py helpers not meant to be imported
└── output/          # generated artifacts: figures, tables, exported results, compiled .typ PDFs
```

If a project folder needs more than one entry-point notebook, prefix each
with `analysis_` followed by a short description (e.g. `analysis_mst.ipynb`,
`analysis_random_walks.ipynb`) instead of a single `analysis.ipynb`.

Only add the subfolders a project actually needs. Don't scaffold empty ones.
If a project folder ever needs more than one notebook, add a `notebooks/`
subfolder inside it too.

Typst-related files (the `.typ` source, `references.bib`, and anything
else the paper needs) live together in a `report/` folder inside the
project, not in `assets/` or a separate top-level `papers/` tree. Compile
into the project's `output/`, never next to the source file. If the report
embeds a generated chart from `output/` (e.g. a figure exported by the
notebook), pass `--root .` from the project folder so Typst's sandbox
covers both `report/` and `output/`:

```
typst compile --root . report/report.typ output/report.pdf
```

Files in `assets/` aren't Python modules, so name them with kebab-case
instead of the `nnn_slug` scheme:

- Papers: `{short-title}-{last-name}-{year}.ext` (e.g.
  `empirical-properties-asset-returns-cont-2001.pdf`)
- Everything else (notes, images, slides): `{title}.ext`, no author needed

Author rules: last name only, never first name. 1–2 authors → list both
(`percival-gregory`); 3+ authors → first author + `et-al` (`kong-et-al`).
