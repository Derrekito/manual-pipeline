# Integration

This section explains how to integrate Manual Pipeline into your project. Two approaches are available: symlink for local development and git submodule for version-controlled integration.

## Method 1: Symlink (Recommended for Local Development)

Create a symlink from your project to the pipeline:

```bash
cd your-project/manual
ln -s ~/Projects/manual-pipeline pipeline
```

Advantages:

- Changes to the pipeline immediately affect all projects
- No additional git complexity
- Easy to update

Disadvantages:

- Requires the pipeline to exist at the expected path
- Not portable across machines without the same path structure

## Method 2: Git Submodule (Recommended for Teams)

Add the pipeline as a git submodule:

```bash
cd your-project
git submodule add <pipeline-repo-url> manual/pipeline
git commit -m "Add manual-pipeline submodule"
```

Clone with submodules:

```bash
git clone --recursive <your-project-url>
```

Or initialize after cloning:

```bash
git submodule update --init --recursive
```

Advantages:

- Version-controlled pipeline reference
- Reproducible builds across machines
- Team members get the exact same version

Disadvantages:

- Additional git commands for updates
- Submodule complexity

## Project Makefile

Create `manual/Makefile` with three required variables:

```makefile
PROJECT_NAME := yourproject
MANUAL_DIR := $(shell pwd)
PIPELINE_DIR := $(MANUAL_DIR)/pipeline

include $(PIPELINE_DIR)/Makefile.include
```

| Variable | Description |
|----------|-------------|
| `PROJECT_NAME` | Base name for output files (e.g., `yourproject-manual.pdf`) |
| `MANUAL_DIR` | Absolute path to the manual directory |
| `PIPELINE_DIR` | Absolute path to the pipeline directory |

### Optional Variables

```makefile
# Override default master document path
MASTER_DOC := $(MANUAL_DIR)/custom-name.md

# Add extra dependencies
EXTRA_DEPS := $(wildcard images/*.png)
```

## Required Project Files

### Master Document

Create `yourproject-manual.md` with \ac{YAML} frontmatter:

```yaml
---
title: "Your Project Manual"
subtitle: "Project Description"
author: "Author Name"
date: "November 2025"
toc: true
secnum: true
acronyms: true
---

# Introduction

Your content here...
```

### Acronyms File

Create `latex/acronyms.tex`:

```text
\begin{acronym}[XXXXXXXX]
\acro{API}{Application Programming Interface}
\acro{CLI}{Command Line Interface}
\end{acronym}
```

The `[XXXXXXXX]` sets the widest label for alignment.

## Optional Project Files

### latexmkrc

Override \ac{LaTeX} compilation settings:

```perl
$pdf_mode = 4;  # Use lualatex
$lualatex = 'lualatex -shell-escape -interaction=batchmode -halt-on-error %O %S';
$biber = 'biber %O %S';
$bibtex_use = 2;
```

### Bibliography

Create `latex/references.bib` and reference in frontmatter:

```yaml
---
bibfile: latex/references.bib
---
```

### Custom Assets

Place project-specific logos or images in `assets/`:

```{.nobreak}
manual/
├── assets/
│   ├── Fonts/      # Custom fonts (optional)
│   └── logos/      # Project logos
```

## Recommended .gitignore

Add to your project's `.gitignore`:

```
manual/build/
manual/output/
manual/venv/
manual/node_modules/
```

## First Build

Run your first build:

```bash
cd your-project/manual
make pdf
```

The pipeline:

1. Detects missing dependencies
2. Creates Python virtual environment
3. Installs npm packages (Mermaid CLI)
4. Downloads fonts if needed
5. Builds the \ac{PDF}

Subsequent builds skip the setup phase.

## Updating the Pipeline

### Symlink Method

The pipeline updates automatically when you pull changes to the pipeline repository.

### Submodule Method

```bash
cd your-project
git submodule update --remote manual/pipeline
git add manual/pipeline
git commit -m "Update manual-pipeline"
```

::: {.readme-only}
## Related Documentation

- [Configuration Options](configuration.md)
- [Troubleshooting](troubleshooting.md)
:::
