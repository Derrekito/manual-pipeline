# Scripts

The pipeline includes three shell scripts that automate the build process. This section documents their functionality and usage.

## create_pdf.sh

The main build orchestrator that transforms Markdown to \ac{PDF} or \ac{DOCX}.

### Location

```
manual-pipeline/scripts/create_pdf.sh
```

### Usage

```bash
MANUAL_DIR=/path/to/manual ./create_pdf.sh <input_file> [toc] [format]
```

| Argument | Description |
|----------|-------------|
| `input_file` | Path to master Markdown document |
| `toc` | Include table of contents: `1` = yes, `0` = no |
| `format` | Output format: `pdf` (default) or `docx` |

### Environment Variables

The script sets and uses these variables:

| Variable | Description |
|----------|-------------|
| `MANUAL_DIR` | Required: project's manual directory |
| `PIPELINE_DIR` | Pipeline location (defaults to script parent) |
| `BUILD_DIR` | Intermediate files (`$MANUAL_DIR/build`) |
| `TEXINPUTS` | \ac{LaTeX} search paths for fonts and logos |
| `LUAFONTDIR` | Font directory for LuaLaTeX |
| `MERMAID_*` | Mermaid diagram configuration |

### Process Flow

1. **Validate** input file exists
2. **Setup** paths and directories
3. **Preprocess** Markdown with `preprocess-acronyms.sh`
4. **Run Pandoc** with filters and template
5. **Compile** with latexmk (for \ac{PDF}) or output directly (for \ac{DOCX})
6. **Move** output to `output/` directory

### Generated Logs

| Log File | Contents |
|----------|----------|
| `build/pandoc_output.log` | Pandoc conversion output |
| `build/latexmk_full_output.log` | Complete latexmk output |
| `build/<name>.log` | LuaLaTeX compilation log |

## check_deps.sh

Verifies and installs dependencies for manual generation.

### Location

```
manual-pipeline/scripts/check_deps.sh
```

### Usage

```bash
./check_deps.sh
```

The script runs automatically on first build via the `setup` target.

### Checked Dependencies

**System Packages**:

| Package | Ubuntu | Fedora | Arch |
|---------|--------|--------|------|
| make | make | make | make |
| pandoc | pandoc | pandoc | pandoc |
| latexmk | texlive-latexmk | texlive-latexmk | texlive-bin |
| lualatex | texlive-luatex | texlive-luatex | texlive-core |
| python3 | python3 | python3 | python |
| pip | python3-pip | python3-pip | python-pip |
| node | nodejs | nodejs | nodejs |
| npm | npm | npm | npm |
| jq | jq | jq | jq |

**Python Packages**:

- `pandocfilters`
- `pygments`

**Node Packages**:

- `@mermaid-js/mermaid-cli@10.9.1`

**Fonts**:

- Fira Code (downloaded from GitHub if missing)

### Behavior

- **Desktop Linux**: Installs missing packages via apt, dnf, or pacman
- **Docker**: Reports missing dependencies without attempting install
- **Virtual Environment**: Creates Python venv for package isolation

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All dependencies satisfied |
| 1 | Missing dependency could not be installed |

## preprocess-acronyms.sh

Protects \ac{LaTeX} acronym commands from Pandoc interpretation.

### Location

```
manual-pipeline/scripts/preprocess-acronyms.sh
```

### Usage

```bash
./preprocess-acronyms.sh input.md > output.md
```

### Transformations

The script wraps acronym commands in raw \ac{LaTeX} syntax:

| Input | Output |
|-------|--------|
| `\ac{API}` | `` `\ac{API}`{=latex} `` |
| `\Ac{API}` | `` `\Ac{API}`{=latex} `` |
| `\acf{API}` | `` `\acf{API}`{=latex} `` |
| `\acs{API}` | `` `\acs{API}`{=latex} `` |
| `\acl{API}` | `` `\acl{API}`{=latex} `` |
| `\acp{API}` | `` `\acp{API}`{=latex} `` |

### Purpose

Without preprocessing, Pandoc interprets `\a` as an escape sequence (bell character), corrupting acronym commands. The backtick wrapper marks the content as raw \ac{LaTeX}, preserving it through conversion.

### Implementation

The script uses `sed` with extended regular expressions:

```bash
sed -E 's/\\ac\{([^}]+)\}/`\\ac{\1}`{=latex}/g'
```

::: {.readme-only}
## Related Documentation

- [Architecture](architecture.md)
- [Troubleshooting](troubleshooting.md)
:::
