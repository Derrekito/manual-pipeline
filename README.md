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

## Project Structure

```
manual-pipeline/
├── latex/
│   ├── preamble.latex     # LaTeX preamble (packages, fixes)
│   ├── template.latex     # Pandoc LaTeX template
│   └── filters/           # Pandoc filters
│       ├── include-files.lua
│       ├── md-links-to-refs.lua
│       ├── nobreak-codeblock.lua
│       ├── notebook-toggle.lua
│       ├── pandoc-mermaid.py
│       ├── pandoc-minted.py
│       └── readme-only.lua
├── scripts/
│   ├── check_deps.sh          # Dependency checker
│   ├── create_pdf.sh          # Main build script
│   └── preprocess-acronyms.sh # Acronym preprocessor
├── Makefile.include           # Include this in your Makefile
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
