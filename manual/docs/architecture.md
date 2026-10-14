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
                    │  │      defaults/              │   │
                    │  │  ├── pdf.yaml               │   │
                    │  │  └── docx.yaml              │   │
                    │  └─────────────────────────────┘   │
                    │              │                     │
                    │              ▼                     │
                    │  ┌─────────────────────────────┐   │
                    │  │      latex/filters/         │   │
                    │  │  ├── page-size.lua          │   │
                    │  │  ├── title-logo.lua         │   │
                    │  │  ├── include-files.lua      │   │
                    │  │  ├── callouts.lua           │   │
                    │  │  ├── readme-only.lua        │   │
                    │  │  ├── notebook-toggle.lua    │   │
                    │  │  ├── nobreak-codeblock.lua  │   │
                    │  │  ├── md-links-to-refs.lua   │   │
                    │  │  ├── table-widths.lua       │   │
                    │  │  ├── inline-code-breaks.lua │   │
                    │  │  ├── table-scale.lua        │   │
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

The reader, template, highlighting and filter order live in
`defaults/pdf.yaml` and `defaults/docx.yaml`. Paths use `${.}` to resolve
relative to the defaults file, so callers can use them from any directory:

```bash
pandoc --defaults /path/to/manual-pipeline/defaults/pdf.yaml input.md -o output.tex
```

Filter execution order matters. The PDF defaults run filters in this sequence:

1. `page-size.lua` - Accept `papersize` as a4, A4 or a4paper
2. `title-logo.lua` - Put front matter logos on the title page
3. `include-files.lua` - Expand `!include` directives
4. `callouts.lua` - Box `> [!NOTE]` alerts
5. `readme-only.lua` - Remove \ac{README}-only sections
6. `notebook-toggle.lua` - Handle code visibility
7. `nobreak-codeblock.lua` - Mark non-breaking code blocks
8. `md-links-to-refs.lua` - Convert links to \ac{LaTeX} references
9. `table-widths.lua` - Choose natural or wrapping columns
10. `inline-code-breaks.lua` - Allow inline code to wrap
11. `table-scale.lua` - Fit wide tables to the line
12. `pandoc-mermaid.py` - Render Mermaid diagrams
13. `pandoc-minted.py` - Configure syntax highlighting

The DOCX defaults keep the same relative order, without `page-size.lua`, `title-logo.lua`,
`readme-only.lua`, `nobreak-codeblock.lua`, `inline-code-breaks.lua` or
`table-scale.lua`.

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
- Tracks dependencies (docs, \ac{LaTeX} files, filters, defaults, build script)
- Auto-triggers setup on first build

### create_pdf.sh

Build orchestrator:

- Sets environment variables (`TEXINPUTS`, font paths, Mermaid config)
- Runs preprocessing and Pandoc with the format's defaults file
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
│   └── logos/           # Example logo; add your own here
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
