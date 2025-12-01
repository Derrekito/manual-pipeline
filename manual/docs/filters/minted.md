# Minted Filter

The minted filter configures code blocks to use the minted \ac{LaTeX} package for syntax highlighting, providing professional-quality code rendering with line numbers and styling.

## Location

```
latex/filters/pandoc-minted.py
```

## Purpose

Default Pandoc code highlighting is basic. Minted uses Pygments, which supports:

- 500+ programming languages
- Multiple color themes
- Line numbering
- Line highlighting
- Background colors
- Frame styles

## Prerequisites

The filter requires:

- Python 3.x
- Pygments package
- \ac{LaTeX} minted package
- Shell escape enabled for \ac{LaTeX}

## Processing

The filter transforms Pandoc code blocks to minted environments. A fenced code block with a language specifier becomes a `terminal` environment in \ac{LaTeX}, which provides syntax highlighting via Pygments.

**Input** (Markdown):
````markdown
```python
def hello():
    print("Hello, World!")
```
````

The filter generates a `terminal` environment wrapping the code, with the language (`python`) as a parameter. The `terminal` environment is defined in `codeblocks.latex` with styling for line numbers, frames, and fonts.

## Language Support

Minted supports any language recognized by Pygments. Common languages:

| Language | Identifier |
|----------|------------|
| Python | `python` |
| JavaScript | `javascript` or `js` |
| Bash | `bash` or `sh` |
| C | `c` |
| C++ | `cpp` |
| Java | `java` |
| Rust | `rust` |
| Go | `go` |
| \ac{YAML} | `yaml` |
| \ac{JSON} | `json` |
| \ac{LaTeX} | `latex` |
| Makefile | `makefile` |

Full list: [Pygments Lexers](https://pygments.org/docs/lexers/)

## Styling

Default styling is configured in `codeblocks.latex`:

```text
\setminted{
    linenos=true,
    breaklines=true,
    frame=single,
    fontsize=\small,
    style=tango
}
```

### Available Options

| Option | Description | Default |
|--------|-------------|---------|
| `linenos` | Show line numbers | `true` |
| `breaklines` | Wrap long lines | `true` |
| `frame` | Border style | `single` |
| `fontsize` | Code font size | `\small` |
| `style` | Pygments theme | `tango` |
| `bgcolor` | Background color | (none) |

### Pygments Themes

Common themes:

- `default` - Neutral colors
- `tango` - GNOME-inspired
- `monokai` - Dark theme
- `friendly` - Light, readable
- `vs` - Visual Studio style
- `github-dark` - GitHub dark mode

Preview themes: `pygmentize -L styles`

## Special Blocks

### No-Break Code

Combine with `.nobreak` class:

````markdown
```{.python .nobreak}
# This block stays together
def function():
    pass
```
````

### Plain Text

For non-highlighted blocks:

````markdown
```text
This is plain text output
without syntax highlighting.
```
````

## Line Numbers

Line numbers are enabled by default. To reference specific lines in text:

```markdown
See line 5 in the following code:

```python
# Line 1
# Line 2
# Line 3
# Line 4
important_line()  # Line 5
```
```

## Troubleshooting

### "shell-escape" Required

Minted requires shell escape. Ensure `latexmkrc` includes:

```perl
$lualatex = 'lualatex -shell-escape ...';
```

### Pygments Not Found

Install Pygments:

```bash
pip install Pygments
```

Or in venv:

```bash
source venv/bin/activate
pip install Pygments
```

### Unknown Language

If a language isn't recognized:

1. Check Pygments documentation for correct identifier
2. Use `text` as fallback
3. Consider if highlighting is needed

## Related Filters

- **nobreak-codeblock**: Prevents page breaks
- **notebook-toggle**: Controls code visibility
