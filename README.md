# manual-pipeline

Centralized Pandoc + LaTeX documentation pipeline for generating PDF/DOCX manuals from Markdown.

## Features

- **LuaLaTeX** PDF generation with full Unicode support
- **Acronym support** with `\ac{}`, `\Ac{}`, `\acf{}`, `\acs{}` commands
- **Mermaid diagrams** (if mmdc installed)
- **Code highlighting** with minted/pygments
- **Algorithm/pseudocode** support
- **TikZ diagrams** with predefined styles
- **Auto-setup** of dependencies on first build
- **TexLive 2025** compatibility fixes included

## Quick Start

1. Add to your project (submodule or symlink):
   ```bash
   # Option A: Git submodule
   cd your-project/manual
   git submodule add ~/Projects/manual-pipeline pipeline

   # Option B: Symlink
   ln -s ~/Projects/manual-pipeline pipeline
   ```

2. Create `manual/Makefile`:
   ```makefile
   PROJECT_NAME := yourproject
   MANUAL_DIR := $(shell pwd)
   PIPELINE_DIR := $(MANUAL_DIR)/pipeline
   include $(PIPELINE_DIR)/Makefile.include
   ```

3. Create your manual:
   ```
   manual/
   ├── Makefile
   ├── yourproject-manual.md
   └── latex/
       └── acronyms.tex
   ```

4. Build:
   ```bash
   make pdf
   ```

## Logos

The title page has no logo unless the front matter names one. A
placeholder, `assets/logos/example-logo.pdf`, shows where it goes:

```yaml
---
title: "My Manual"
logo: example-logo.pdf            # or [ours.pdf, partner.pdf]
logo-width: 0.3\textwidth         # optional, 0.25\textwidth by default
---
```

Put your own logo in your project's `manual/assets/logos/` and name it in
`logo`. Logo files other than the example are git-ignored here, so a logo
dropped into the pipeline's `assets/logos/` stays out of this repository.
The placeholder is drawn by `assets/logos/example-logo.tex`; edit it and
run `lualatex example-logo.tex` to make your own.

## Page Size

US letter by default. Set `papersize: a4` (or `a5`, `legal`, ...) to
change the paper, and `geometry: [margin=2cm]` to replace the margins or
give a custom `paperwidth`/`paperheight`.

## Callouts

GitHub alerts become coloured boxes in the PDF:

```markdown
> [!NOTE]
> Example note

> [!WARNING] Custom title
> Text after the marker replaces the title.
```

`NOTE`, `TIP`, `IMPORTANT`, `WARNING` and `CAUTION` have their own colour
and icon; other words (`NOTES`, `INFO`, `DANGER`, ...) take the nearest
style. The box breaks across pages. See `latex/filters/callouts.lua`.

## Project Structure

```
manual-pipeline/
├── latex/
│   ├── preamble.latex     # LaTeX preamble (packages, fixes)
│   ├── template.latex     # Pandoc LaTeX template
│   └── filters/           # Pandoc filters
│       ├── callouts.lua
│       ├── include-files.lua
│       ├── inline-code-breaks.lua
│       ├── md-links-to-refs.lua
│       ├── nobreak-codeblock.lua
│       ├── notebook-toggle.lua
│       ├── pandoc-mermaid.py
│       ├── pandoc-minted.py
│       ├── readme-only.lua
│       ├── table-scale.lua
│       ├── table-widths.lua
│       └── title-logo.lua
├── scripts/
│   ├── check_deps.sh          # Dependency checker
│   ├── create_pdf.sh          # Main build script
│   └── preprocess-acronyms.sh # Acronym preprocessor
├── Makefile.include           # Include this in your Makefile
├── tests/                     # The filters and template, run through pandoc
└── examples/
    └── Makefile.example
```

## Your Project Structure

```
your-project/
├── manual/
│   ├── Makefile              # Includes pipeline
│   ├── yourproject-manual.md # Main document
│   ├── latex/
│   │   └── acronyms.tex      # Project-specific acronyms
│   ├── assets/               # Project-specific images/fonts
│   │   └── Fonts/
│   ├── build/                # Generated (gitignore)
│   └── output/               # PDF/DOCX output
└── ...
```

## Acronyms

Create `manual/latex/acronyms.tex`:
```latex
\begin{acronym}
\acro{API}{Application Programming Interface}
\acro{CPU}{Central Processing Unit}
\end{acronym}
```

Use in markdown:
```markdown
The \ac{API} provides access to the \ac{CPU}.
```

## Narrow pages and wide tables

Three filters keep text inside the margins. A table that is wider than
the line is shrunk to fit: `table-widths.lua` marks it and
`table-scale.lua` measures it in LaTeX and scales its font and column gap
by exactly the ratio needed. It stays a longtable, so it still breaks
across pages, and a table that fits is untouched. A table that would have
to shrink below `table-min-scale` (default 0.6) gets wrapping columns
instead; `table-fit-chars` (default 72) is the line length in characters
used for that estimate, lower for a narrow page. Pipe tables whose source
lines are long already get wrapping columns from pandoc and are left
alone. `inline-code-breaks.lua` lets inline code break after
`/ _ . - = ,`, in the same font as `\mintinline` and at a size relative to
the text around it, so it shrinks with a scaled table.

Settings passed with `pandoc -H file.tex`, or `header-includes` in the
front matter, are placed last before `\begin{document}`, so they can change
the page size, headers or image limits without copying the template:

```latex
\geometry{paperwidth=158mm, paperheight=210mm, margin=8mm, includeheadfoot}
```

The body text is 11pt; `fontsize: 10pt` in the front matter, or
`pandoc -V fontsize=10pt`, sets another size the article class has
(10pt, 11pt or 12pt).

## Tests

```bash
python3 -m unittest discover -s tests
```

They run the filters and the template through pandoc, with a stand-in for
`mmdc`. One compiles a wide table with LuaLaTeX to check it fits, and is
skipped without it.

## Dependencies

- Pandoc 3.x
- TexLive 2024+ (lualatex, latexmk)
- Python 3.x with pygments
- Optional: Node.js with @mermaid-js/mermaid-cli

Run `make check-deps` to verify.

## Make Targets

| Target | Description |
|--------|-------------|
| `make pdf` | Generate PDF (default) |
| `make docx` | Generate DOCX |
| `make setup` | Install dependencies |
| `make check-deps` | Verify dependencies |
| `make clean` | Remove build artifacts |
| `make distclean` | Remove all generated files |

## License

MIT
