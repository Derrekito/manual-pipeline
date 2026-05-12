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

Logos are configured via `logos.yaml` in the pipeline root directory. Copy `logos.yaml.example` to `logos.yaml` and customize for your organization.

Each logo defined in `logos.yaml` becomes a frontmatter boolean:

```yaml
---
myorglogo: true     # Enable your custom logo
partnerlogo: true   # Enable partner logo
---
```

See `logos.yaml.example` for the logo configuration format.

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
