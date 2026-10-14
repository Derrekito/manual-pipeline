# Configuration

Manual Pipeline is configured through \ac{YAML} frontmatter in your master document, environment variables, and optional configuration files.

## YAML Frontmatter

The master document begins with \ac{YAML} frontmatter that controls document metadata and features.

### Required Fields

```yaml
---
title: "Document Title"
---
```

### Recommended Fields

```yaml
---
title: "Document Title"
subtitle: "Descriptive Subtitle"
author: "Author Name"
date: "November 2025"
---
```

### Feature Flags

```yaml
---
toc: true        # Generate table of contents
secnum: true     # Number sections
acronyms: true   # Include acronym list
---
```

### Document Metadata

```yaml
---
version: "1.0.0"
disclaimer: "Internal Use Only"
abstract: |
  Multi-line abstract text
  that describes the document.
---
```

### Logo Options

The title page shows no logo unless `logo` is set. The pipeline ships one
placeholder, `example-logo.pdf`, to show where a logo goes:

```yaml
---
logo: example-logo.pdf            # one logo, or [ours.pdf, partner.pdf] for several
logo-width: 0.3\textwidth         # optional, 0.25\textwidth by default
---
```

A bare file name is looked up in `manual/assets/logos/` (the manual
directory, not the project root), then the pipeline's `assets/logos/`. A path is taken relative to the manual directory. To use your
own logo, put it in `manual/assets/logos/` and name it here; to change the
placeholder itself, edit `assets/logos/example-logo.tex` and rebuild it with
`lualatex example-logo.tex`.

### Page Size

Pages are US letter with 1 in side margins unless the front matter says
otherwise:

```yaml
---
papersize: a4                     # a4, A4 or a4paper; also a5, legal, ...
geometry: [margin=2cm]            # replaces the default margins
---
```

`geometry` takes any options of the geometry package, so a custom size is
`geometry: [paperwidth=180mm, paperheight=240mm, margin=10mm]`. Both can
also be given on the pandoc command line with `-M`, and a later
`\geometry{...}` in `header-includes` still overrides everything.

### Bibliography

```yaml
---
bibfile: latex/references.bib
---
```

### Notebook Control

```yaml
---
notebook: false  # Suppress code blocks in PDF
---
```

## Complete Frontmatter Example

```yaml
---
title: "RADCaST Manual"
subtitle: "Radiation Anomaly Detection, Capture, and Streaming Telemetry"
author: "RADCaST Development Team"
date: "November 2025"
version: "2.0.0"
toc: true
secnum: true
acronyms: true
bibfile: latex/references.bib
abstract: |
  This manual documents the RADCaST system for radiation
  effects testing and data acquisition.
---
```

## Environment Variables

The build scripts respond to these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `MANUAL_DIR` | (required) | Path to project's manual directory |
| `PIPELINE_DIR` | (required) | Path to manual-pipeline directory |
| `TEXINPUTS` | (set by script) | \ac{LaTeX} input search paths |
| `LUAFONTDIR` | (set by script) | Font directory for LuaLaTeX |

## Makefile Variables

Set these in your project Makefile before including `Makefile.include`:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PROJECT_NAME` | Yes | - | Base name for outputs |
| `MANUAL_DIR` | Yes | - | Manual directory path |
| `PIPELINE_DIR` | Yes | - | Pipeline directory path |
| `MASTER_DOC` | No | `$(PROJECT_NAME)-manual.md` | Master document path |
| `EXTRA_DEPS` | No | - | Additional build dependencies |

## Mermaid Configuration

Configure Mermaid diagram rendering in `config/mermaid-config.json`:

```json
{
  "theme": "default",
  "themeVariables": {
    "nodeBorder": "#004990",
    "mainBkg": "#c9d7e4",
    "nodeTextColor": "#274059",
    "fontFamily": "arial",
    "fontSize": "18px"
  }
}
```

Customize styling in `config/mermaid.css`.

## Puppeteer Configuration

Configure headless Chrome for diagram rendering in `config/puppeteer.json`:

```json
{
  "executablePath": "/usr/bin/chromium",
  "args": [
    "--no-sandbox",
    "--disable-setuid-sandbox",
    "--font-render-hinting=none"
  ]
}
```

Adjust `executablePath` for your system's Chromium location.

## LaTeX Configuration

### latexmkrc

Control \ac{LaTeX} compilation in `latexmkrc`:

```perl
$pdf_mode = 4;           # 4 = lualatex
$lualatex = 'lualatex -shell-escape -interaction=batchmode -halt-on-error %O %S';
$biber = 'biber %O %S';  # Bibliography processor
$bibtex_use = 2;         # 2 = run biber for biblatex
```

### Acronym Definitions

Define project-specific acronyms in `latex/acronyms.tex`:

```text
\begin{acronym}[XXXXXXXX]
\acro{API}{Application Programming Interface}
\acro{CPU}{Central Processing Unit}
\acro{DUT}{Device Under Test}
\end{acronym}
```

Commands available in Markdown:

| Command | Description | Example Output |
|---------|-------------|----------------|
| `\ac{API}` | Smart (full first, short after) | Application Programming Interface (API) |
| `\Ac{API}` | Capitalized smart | Application Programming Interface (API) |
| `\acf{API}` | Always full | Application Programming Interface (API) |
| `\acs{API}` | Always short | API |
| `\acl{API}` | Always long | Application Programming Interface |
| `\acp{API}` | Plural | APIs |

## Font Configuration

The pipeline uses these fonts by default:

- **Body Text**: TeX Gyre Termes (Times-like)
- **Code**: Fira Code (ligatures supported)
- **Monospace**: TeX Gyre Cursor

Fira Code is downloaded automatically if not found.

To use custom fonts, place `.ttf` files in `assets/Fonts/` and modify `latex/fonts.latex`.

::: {.readme-only}
## Related Documentation

- [Template Reference](templates.md)
- [Filter Documentation](filters/)
:::
