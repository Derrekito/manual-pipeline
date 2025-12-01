# Troubleshooting

This section addresses common issues encountered when using Manual Pipeline and provides solutions.

## Build Failures

### "PROJECT_NAME is not set"

**Symptom**: Make fails immediately with variable error.

**Cause**: Required Makefile variables are missing.

**Solution**: Ensure your Makefile sets all required variables before the include:

```makefile
PROJECT_NAME := yourproject
MANUAL_DIR := $(shell pwd)
PIPELINE_DIR := $(MANUAL_DIR)/pipeline

include $(PIPELINE_DIR)/Makefile.include
```

### "MANUAL_DIR must be set"

**Symptom**: `create_pdf.sh` fails with environment error.

**Cause**: Script called directly without environment.

**Solution**: Always use `make pdf` instead of running scripts directly. The Makefile exports required variables.

### Pandoc Fails with "Could not open file"

**Symptom**: Include directive cannot find file.

**Cause**: Path in `!include` directive is incorrect.

**Solution**:

1. Paths are relative to the master document, not the current directory
2. Check for typos in the path
3. Verify the file exists: `ls -la docs/yourfile.md`

Example correct usage:

```markdown
# From yourproject-manual.md in manual/
!include-headless docs/intro.md          # Correct: relative to manual/
!include-headless ../README.md           # Correct: parent directory
```

### latexmk Fails with "Emergency stop"

**Symptom**: \ac{LaTeX} compilation aborts with errors.

**Cause**: \ac{LaTeX} syntax error or missing package.

**Solution**:

1. Check `build/<name>.log` for the specific error
2. Look for "!" lines indicating the error location
3. Common causes:
   - Unescaped special characters (`_`, `&`, `%`, `#`)
   - Missing `\end{}` for opened environments
   - Invalid acronym reference

### Missing Fonts

**Symptom**: LuaLaTeX warns about missing fonts; output uses substitutes.

**Cause**: Required fonts not installed.

**Solution**:

```bash
make check-deps
```

If Fira Code is missing, the script downloads it automatically. For system fonts:

```bash
# Arch Linux
sudo pacman -S ttf-fira-code noto-fonts-emoji

# Ubuntu
sudo apt-get install fonts-firacode fonts-noto-color-emoji
```

## Acronym Issues

### Acronyms Show as "\ac{...}"

**Symptom**: Acronym commands appear literally in output.

**Cause**: Preprocessor didn't run or failed.

**Solution**:

1. Check that `preprocess-acronyms.sh` is executable
2. Verify the temporary preprocessed file is created
3. Check `pandoc_output.log` for preprocessing errors

### "Acronym undefined"

**Symptom**: \ac{LaTeX} warning about undefined acronym.

**Cause**: Acronym used but not defined in `acronyms.tex`.

**Solution**:

1. Add the acronym to `latex/acronyms.tex`:

```text
\acro{API}{Application Programming Interface}
```

2. Rebuild the document

### First Use Shows Short Form

**Symptom**: Acronym should expand on first use but shows only abbreviation.

**Cause**: The acronym appeared earlier in the document (possibly in \ac{TOC}).

**Solution**:

- This is expected behavior for the `acronym` package
- Use `\acf{API}` to force full form
- Consider the `noredefwarn` package option

## Mermaid Diagram Issues

### Diagrams Not Rendering

**Symptom**: Mermaid code blocks appear as text.

**Cause**: Mermaid \ac{CLI} not installed or not found.

**Solution**:

```bash
# Check if mmdc is available
./node_modules/.bin/mmdc --version

# Reinstall if needed
npm install @mermaid-js/mermaid-cli@10.9.1
```

### Chromium Sandbox Errors

**Symptom**: Mermaid fails with sandbox permission errors.

**Cause**: Chromium security restrictions in some environments.

**Solution**: Update `config/puppeteer.json`:

```json
{
  "executablePath": "/usr/bin/chromium",
  "args": [
    "--no-sandbox",
    "--disable-setuid-sandbox"
  ]
}
```

### Diagrams Render Incorrectly

**Symptom**: Diagram styling or layout is wrong.

**Cause**: Mermaid configuration issue.

**Solution**:

1. Validate your Mermaid syntax at [mermaid.live](https://mermaid.live)
2. Check `config/mermaid-config.json` for theme settings
3. Ensure Mermaid version compatibility

## Code Highlighting Issues

### No Syntax Highlighting

**Symptom**: Code blocks appear without colors.

**Cause**: Pygments not installed or minted not configured.

**Solution**:

```bash
# Check Pygments
python3 -c "import pygments; print(pygments.__version__)"

# Install if missing
pip install Pygments
```

### "shell-escape" Errors

**Symptom**: latexmk fails with minted permission errors.

**Cause**: Shell escape not enabled for minted.

**Solution**: Verify `latexmkrc` includes shell-escape:

```perl
$lualatex = 'lualatex -shell-escape -interaction=batchmode %O %S';
```

## Performance Issues

### Slow First Build

**Symptom**: Initial build takes several minutes.

**Cause**: Dependency installation, font downloads, initial caching.

**Solution**: This is expected. Subsequent builds are much faster. To speed up:

1. Pre-run `make setup` before building
2. Reuse `venv/` and `node_modules/` across builds

### Slow Incremental Builds

**Symptom**: Small changes trigger long rebuilds.

**Cause**: Full rebuild triggered by dependency changes.

**Solution**:

1. Run `make clean` to clear cached files
2. Check if filter files were modified
3. Consider using `make distclean` for a fresh start

## Output Issues

### \ac{PDF} Not Generated

**Symptom**: Build completes but no \ac{PDF} in `output/`.

**Cause**: \ac{PDF} generated but not moved.

**Solution**:

1. Check `build/` for the \ac{PDF} file
2. Review `latexmk_full_output.log` for errors
3. Verify `output/` directory exists and is writable

### Broken Cross-References

**Symptom**: References show "??" instead of page/section numbers.

**Cause**: Insufficient \ac{LaTeX} passes.

**Solution**: latexmk should handle this automatically. If not:

```bash
make clean && make pdf
```

### Images Not Appearing

**Symptom**: Figures show as boxes or are missing.

**Cause**: Image path incorrect or format unsupported.

**Solution**:

1. Use relative paths from the document location
2. Prefer \ac{PDF} or \ac{PNG} formats
3. Place images in `assets/` and reference them

## Getting Help

If these solutions don't resolve your issue:

1. Check `build/*.log` files for detailed error messages
2. Run `make clean && make pdf` for a fresh build
3. Verify all dependencies with `make check-deps`
4. Test with a minimal document to isolate the problem

::: {.readme-only}
## Related Documentation

- [Architecture](architecture.md)
- [Scripts Reference](scripts.md)
:::
