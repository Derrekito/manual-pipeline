# Architecture

Manual Pipeline orchestrates multiple tools to transform Markdown source files into professional \ac{PDF} and \ac{DOCX} documents. This section describes the pipeline's structure, data flow, and key components.

## Pipeline Overview

The build process flows through three stages:

```{.nobreak}
                    ┌─────────────────────────────────────┐
                    │          manual-pipeline            │
                    ├─────────────────────────────────────┤
                    │                                     │
  Makefile.include  │  ┌─────────────────────────────┐   │
        │           │  │      scripts/               │   │
        ▼           │  │  ├── check_deps.sh          │   │
  ┌──────────┐      │  │  ├── create_pdf.sh          │   │
  │  make    │──────┼──│  └── preprocess-acronyms.sh │   │
  │  pdf     │      │  └─────────────────────────────┘   │
  └──────────┘      │              │                     │
                    │              ▼                     │
                    │  ┌─────────────────────────────┐   │
                    │  │      latex/filters/         │   │
                    │  │  ├── include-files.lua      │   │
                    │  │  ├── readme-only.lua        │   │
                    │  │  ├── notebook-toggle.lua    │   │
                    │  │  ├── nobreak-codeblock.lua  │   │
                    │  │  ├── md-links-to-refs.lua   │   │
                    │  │  ├── pandoc-mermaid.py      │   │
                    │  │  └── pandoc-minted.py       │   │
                    │  └─────────────────────────────┘   │
                    │              │                     │
                    │              ▼                     │
                    │  ┌─────────────────────────────┐   │
                    │  │      latex/                 │   │
                    │  │  ├── template.latex         │   │
                    │  │  ├── preamble.latex         │   │
                    │  │  ├── codeblocks.latex       │   │
                    │  │  ├── fonts.latex            │   │
                    │  │  ├── styles.latex           │   │
                    │  │  └── titlepage.latex        │   │
                    │  └─────────────────────────────┘   │
                    │                                     │
                    └─────────────────────────────────────┘
```

## Stage 1: Preprocessing

Before Pandoc processes the document, `preprocess-acronyms.sh` protects \ac{LaTeX} acronym commands from being corrupted:

| Input | Output |
|-------|--------|
| `\ac{API}` | `` `\ac{API}`{=latex} `` |
| `\Ac{API}` | `` `\Ac{API}`{=latex} `` |

This wrapping prevents Pandoc from interpreting `\a` as an escape sequence.

## Stage 2: Pandoc Conversion

Pandoc transforms preprocessed Markdown to \ac{LaTeX} using:

1. **Input Format**: `markdown+raw_tex` enables inline \ac{LaTeX}
2. **Lua Filters**: Process includes, strip content, transform links
3. **Python Filters**: Render Mermaid diagrams, configure code highlighting
4. **Template**: Assembles document structure with preamble and styles

Filter execution order matters. The pipeline runs filters in this sequence:

1. `include-files.lua` - Expand `!include` directives
2. `readme-only.lua` - Remove \ac{README}-only sections
3. `notebook-toggle.lua` - Handle code visibility
4. `nobreak-codeblock.lua` - Mark non-breaking code blocks
5. `md-links-to-refs.lua` - Convert links to \ac{LaTeX} references
6. `pandoc-mermaid.py` - Render Mermaid diagrams
7. `pandoc-minted.py` - Configure syntax highlighting

## Stage 3: LaTeX Compilation

For \ac{PDF} output, latexmk compiles the \ac{LaTeX} source with LuaLaTeX:

```bash
latexmk -lualatex -shell-escape -output-directory=build document.tex
```

Key options:

- `-lualatex`: Use LuaLaTeX engine for Unicode support
- `-shell-escape`: Required for minted syntax highlighting
- `-output-directory`: Keep build artifacts separate

Latexmk automatically runs multiple passes to resolve cross-references and bibliography.

## Component Responsibilities

### Makefile.include

Central build logic:

- Validates required variables (`PROJECT_NAME`, `MANUAL_DIR`, `PIPELINE_DIR`)
- Defines targets: `pdf`, `docx`, `setup`, `check-deps`, `clean`, `distclean`
- Tracks dependencies (docs, \ac{LaTeX} files, filters)
- Auto-triggers setup on first build

### create_pdf.sh

Build orchestrator:

- Sets environment variables (`TEXINPUTS`, font paths, Mermaid config)
- Runs preprocessing and Pandoc
- Invokes latexmk for \ac{PDF} output
- Handles \ac{DOCX} conversion directly via Pandoc

### Template System

Modular \ac{LaTeX} template:

- `template.latex`: Main structure with Pandoc variable substitution
- `preamble.latex`: Package imports and configuration
- `fonts.latex`: Font setup for LuaLaTeX
- `codeblocks.latex`: Minted environment configuration
- `styles.latex`: Document formatting
- `titlepage.latex`: Custom title page

## Asset Management

The pipeline centralizes shared assets:

```{.nobreak}
manual-pipeline/
├── assets/
│   ├── Fonts/           # FiraCode, Hack, Roboto
│   └── logos/           # Organization logos
└── config/
    ├── mermaid-config.json
    ├── mermaid.css
    └── puppeteer.json
```

Projects can override with their own `assets/` directory. The build script searches project assets first, then pipeline assets.

## Output Structure

```{.nobreak}
manual/
├── build/                  # Intermediate files
│   ├── document.tex        # Generated LaTeX
│   ├── document.aux        # Cross-references
│   ├── document.log        # Compilation log
│   ├── _minted/            # Syntax highlighting cache
│   └── mermaid_images/     # Rendered diagrams
└── output/
    └── document.pdf        # Final output
```

::: {.readme-only}
## Related Documentation

- [Integration Guide](integration.md)
- [Template Reference](templates.md)
- [Filter Documentation](filters/)
:::
