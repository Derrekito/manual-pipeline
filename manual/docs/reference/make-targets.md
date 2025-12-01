# Make Targets

This section documents all Make targets provided by `Makefile.include`.

## Primary Targets

### pdf

Generate \ac{PDF} output from the master document.

```bash
make pdf
```

This is the default target; running `make` alone is equivalent.

**Behavior**:

1. Checks for setup marker; runs setup if missing
2. Preprocesses Markdown for acronym protection
3. Runs Pandoc with all filters
4. Compiles \ac{LaTeX} with latexmk/LuaLaTeX
5. Moves output to `output/$(PROJECT_NAME)-manual.pdf`

**Dependencies**:

- Setup marker (`venv/.setup_complete`)
- Master document
- All `docs/*.md` files
- All `latex/*.tex` files
- All filter files

### docx

Generate Microsoft Word (\ac{DOCX}) output.

```bash
make docx
```

**Behavior**:

1. Checks for setup marker; runs setup if missing
2. Runs Pandoc directly (no \ac{LaTeX} step)
3. Outputs to `output/$(PROJECT_NAME)-manual.docx`

**Notes**:

- Some \ac{LaTeX}-specific features may not render
- Mermaid diagrams are included as images
- Acronyms expand as plain text

## Setup Targets

### setup

Install all dependencies and create the setup marker.

```bash
make setup
```

**Actions**:

1. Runs `check_deps.sh`
2. Creates Python virtual environment
3. Installs Python packages (pandocfilters, Pygments)
4. Installs npm packages (Mermaid \ac{CLI})
5. Downloads fonts if needed
6. Creates `.setup_complete` marker

**When to use**:

- Before first build (automatically triggered)
- After updating the pipeline
- When dependencies seem broken

### check-deps

Verify system dependencies without full setup.

```bash
make check-deps
```

**Actions**:

1. Checks for required system packages
2. Verifies Python packages
3. Verifies npm packages
4. Checks for fonts
5. Reports missing dependencies

**Exit codes**:

- 0: All dependencies satisfied
- 1: Missing dependency

## Cleanup Targets

### clean

Remove build artifacts while preserving output.

```bash
make clean
```

**Removes**:

- `build/` directory (LaTeX intermediate files)
- Minted cache
- Mermaid image cache
- Log files

**Preserves**:

- `output/` directory (final \ac{PDF}/\ac{DOCX})
- `venv/` directory (Python environment)
- `node_modules/` (npm packages)

### distclean

Remove all generated files for a fresh start.

```bash
make distclean
```

**Removes**:

- Everything `clean` removes
- `output/` directory
- `venv/` directory
- Setup marker

**Preserves**:

- `node_modules/` (npm packages, as they take time to download)

**When to use**:

- Troubleshooting persistent issues
- Before archiving the project
- Testing fresh builds

## Informational Targets

### help

Display available targets and usage information.

```bash
make help
```

**Output**:

```
yourproject Manual Generation (using manual-pipeline)

Targets:
  make pdf        - Generate PDF manual
  make docx       - Generate DOCX manual
  make setup      - Install dependencies (auto-runs on first build)
  make check-deps - Verify system dependencies
  make clean      - Remove build artifacts
  make distclean  - Remove all generated files including venv

Output: /path/to/manual/output/
```

## Target Dependencies

```{.nobreak}
        ┌─────────────────┐
        │     setup       │
        └────────┬────────┘
                 │
                 ▼
        ┌─────────────────┐
        │  .setup_complete│ (marker file)
        └────────┬────────┘
                 │
        ┌────────┴────────┐
        ▼                 ▼
┌───────────────┐ ┌───────────────┐
│      pdf      │ │     docx      │
└───────────────┘ └───────────────┘
```

## Common Workflows

### First Build

```bash
cd your-project/manual
make pdf
# Automatically runs setup, then builds
```

### Incremental Update

```bash
# Edit docs/
make pdf
# Only rebuilds if sources changed
```

### Fresh Rebuild

```bash
make clean
make pdf
```

### Complete Reset

```bash
make distclean
make pdf
```

### Quick Dependency Check

```bash
make check-deps
# If issues, run: make setup
```
