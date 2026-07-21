# Contributing

## Notebook and project naming convention

Everything in `notebooks/` shares a single sequence number, whether it's a
standalone notebook or a folder of resources:

```
notebooks/NNN_slug.ipynb    # standalone notebook, no supporting resources
notebooks/NNN_slug/         # project folder, when resources are needed
```

Numbers are unique across both forms and assigned in chronological order —
don't reuse or reorder them.

### Inside a project folder

Use a fixed entry-point notebook name (`analysis.ipynb`), not the slug again,
and organize supporting resources into generic subfolders as needed:

```
notebooks/NNN_slug/
├── analysis.ipynb   # entry point
├── data/            # raw or processed datasets (csv, parquet, etc.)
├── assets/          # reference material: papers, PDFs, images, slides
├── scripts/         # standalone .py helpers not meant to be imported
└── output/          # generated artifacts: figures, tables, exported results
```

Only add the subfolders a project actually needs — don't scaffold empty ones.
If a project folder ever needs more than one notebook, add a `notebooks/`
subfolder inside it too.

Files in `assets/` aren't Python modules, so name them with kebab-case
instead of the `NNN_slug` scheme:

- Papers: `{short-title}-{last-name}-{year}.ext` (e.g.
  `empirical-properties-asset-returns-cont-2001.pdf`)
- Everything else (notes, images, slides): `{title}.ext` — no author needed

Author rules: last name only, never first name. 1–2 authors → list both
(`percival-gregory`); 3+ authors → first author + `et-al` (`kong-et-al`).
