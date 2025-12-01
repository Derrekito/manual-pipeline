# Environment Variables

This section documents environment variables used by Manual Pipeline scripts.

## Required Variables

These variables must be set when running scripts directly. The Makefile sets them automatically.

### MANUAL_DIR

Path to the project's manual directory.

```bash
MANUAL_DIR=/home/user/project/manual
```

**Used by**: `create_pdf.sh`, `check_deps.sh`

**Set by**: Makefile (via `export`)

### PIPELINE_DIR

Path to the manual-pipeline installation.

```bash
PIPELINE_DIR=/home/user/Projects/manual-pipeline
```

**Used by**: `create_pdf.sh`

**Default**: Parent directory of the script (when run directly)

## Build Variables

These variables control the build process.

### TEXINPUTS

\ac{LaTeX} search path for fonts, logos, and includes.

```bash
TEXINPUTS=project/assets/logos:pipeline/assets/logos:pipeline/assets/Fonts:
```

**Set by**: `create_pdf.sh`

**Purpose**: Allows \ac{LaTeX} to find:

- Project-specific logos
- Pipeline shared logos
- Fira Code and other fonts

### LUAFONTDIR

Font directory for LuaLaTeX font discovery.

```bash
LUAFONTDIR=/path/to/pipeline/assets/Fonts
```

**Set by**: `create_pdf.sh`

**Purpose**: LuaLaTeX font path for fontspec package.

## Mermaid Variables

These variables configure Mermaid diagram rendering.

### MERMAID_FILTER_CONFIG

Path to Mermaid configuration \ac{JSON}.

```bash
MERMAID_FILTER_CONFIG=/path/to/config/mermaid-config.json
```

**Set by**: `create_pdf.sh`

**Contents**: Theme settings, colors, fonts

### MERMAID_FILTER_MERMAID_CSS

Path to Mermaid \ac{CSS} customization.

```bash
MERMAID_FILTER_MERMAID_CSS=/path/to/config/mermaid.css
```

**Set by**: `create_pdf.sh`

### MERMAID_BIN

Path to Mermaid \ac{CLI} executable.

```bash
MERMAID_BIN=/path/to/node_modules/.bin/mmdc
```

**Set by**: `create_pdf.sh`

**Purpose**: Filter uses this to invoke mmdc

### MERMAID_OUTPUT_DIR

Directory for rendered Mermaid images.

```bash
MERMAID_OUTPUT_DIR=/path/to/build/mermaid_images
```

**Set by**: `create_pdf.sh`

## Debug Variables

### PANDOC_TRACE

Enable Pandoc tracing output.

```bash
PANDOC_TRACE=1 make pdf
```

**Purpose**: Debug filter execution order and processing

### LATEXMK_VERBOSE

Show detailed latexmk output.

```bash
LATEXMK_VERBOSE=1 make pdf
```

**Purpose**: Debug \ac{LaTeX} compilation issues

## Variable Summary

| Variable | Required | Set By | Purpose |
|----------|----------|--------|---------|
| `MANUAL_DIR` | Yes | Makefile | Project manual location |
| `PIPELINE_DIR` | Yes | Makefile/default | Pipeline installation |
| `TEXINPUTS` | Auto | create_pdf.sh | \ac{LaTeX} search paths |
| `LUAFONTDIR` | Auto | create_pdf.sh | LuaLaTeX fonts |
| `MERMAID_*` | Auto | create_pdf.sh | Diagram rendering |

## Overriding Variables

### In Makefile

```makefile
export MY_VAR := value
```

### On Command Line

```bash
MY_VAR=value make pdf
```

### In Environment

```bash
export MY_VAR=value
make pdf
```

## Debugging Variable Issues

Check current values:

```bash
make pdf 2>&1 | grep -E "MANUAL_DIR|PIPELINE_DIR|TEXINPUTS"
```

Print all exported variables:

```bash
env | grep -E "MANUAL|PIPELINE|MERMAID|TEX"
```
