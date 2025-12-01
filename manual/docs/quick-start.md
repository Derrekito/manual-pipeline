# Quick Start

This section provides the fastest path to generating your first manual with Manual Pipeline.

## Prerequisites

Ensure your system has:

- Pandoc 3.x
- TexLive 2024+ with LuaLaTeX
- Python 3.x with pip
- Node.js and npm (for Mermaid diagrams)
- Make

On Arch Linux:

```bash
sudo pacman -S pandoc texlive-core texlive-latexextra texlive-fontsextra \
  texlive-luatex python python-pip nodejs npm make
```

On Debian/Ubuntu:

```bash
sudo apt-get install pandoc texlive-full python3 python3-pip nodejs npm make
```

## Setup

1. Clone or link the pipeline to your project:

```bash
cd your-project/manual
ln -s ~/Projects/manual-pipeline pipeline
```

2. Create your Makefile:

```makefile
PROJECT_NAME := yourproject
MANUAL_DIR := $(shell pwd)
PIPELINE_DIR := $(MANUAL_DIR)/pipeline

include $(PIPELINE_DIR)/Makefile.include
```

3. Create your master document (`yourproject-manual.md`):

```yaml
---
title: "Your Project Manual"
subtitle: "Project Description"
author: "Your Name"
date: "November 2025"
toc: true
secnum: true
acronyms: true
---

# Introduction

Your content here...
```

4. Create your acronyms file (`latex/acronyms.tex`):

```text
\begin{acronym}
\acro{API}{Application Programming Interface}
\acro{CLI}{Command Line Interface}
\end{acronym}
```

5. Build:

```bash
make pdf
```

The first build runs `make setup` automatically to install dependencies.

## Directory Structure

After setup, your project should look like:

```{.nobreak}
your-project/
├── manual/
│   ├── Makefile              # 3-line wrapper
│   ├── yourproject-manual.md # Master document
│   ├── pipeline -> ...       # Link to manual-pipeline
│   ├── latex/
│   │   └── acronyms.tex      # Project acronyms
│   ├── docs/                 # Optional: modular docs
│   ├── build/                # Generated (gitignored)
│   └── output/               # PDF/DOCX output
└── ...
```

## Quick Commands

| Command | Description |
|---------|-------------|
| `make pdf` | Generate \ac{PDF} (default) |
| `make docx` | Generate \ac{DOCX} |
| `make setup` | Install dependencies |
| `make check-deps` | Verify dependencies |
| `make clean` | Remove build artifacts |
| `make distclean` | Remove all generated files |

## Including External Files

Split large documents into separate files:

```markdown
# Introduction

!include-headless docs/intro.md

# Architecture

!include-headless docs/architecture.md
```

The `!include-headless` directive includes the file and strips its first heading.

## Using Acronyms

Define in `latex/acronyms.tex`:

```text
\acro{API}{Application Programming Interface}
```

Use in Markdown:

```markdown
The \ac{API} provides...    # Full form on first use
Call the \ac{API} again...  # Short form thereafter
```

::: {.readme-only}
## Next Steps

- [Configuration Options](configuration.md)
- [Filter Documentation](filters/)
- [Troubleshooting](troubleshooting.md)
:::
