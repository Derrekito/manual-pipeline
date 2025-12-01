# Readme Only Filter

The readme-only filter removes content marked for \ac{README} display only, allowing sections to appear in standalone Markdown files while being excluded from the compiled manual.

## Location

```
latex/filters/readme-only.lua
```

## Purpose

Some content is appropriate for GitHub \ac{README} files but not for formal documentation:

- Navigation links to other documentation files
- Badges and status indicators
- GitHub-specific formatting
- Related documentation links

This filter enables maintaining single-source files that work both as standalone documents and as included sections.

## Syntax

Wrap content in a fenced div with the `readme-only` class:

```markdown
Regular content appears everywhere.

::: {.readme-only}
This section only appears in the README.
It will be stripped from the PDF.

- [Link to other file](other.md)
- [Back to index](../README.md)
:::

More regular content.
```

## Processing

The filter removes all div elements with class `readme-only` from the document tree during Pandoc conversion. The content is:

- **Visible** in GitHub/GitLab rendered Markdown
- **Visible** when viewing the raw Markdown file
- **Hidden** in \ac{PDF} and \ac{DOCX} output

## Use Cases

### Navigation Links

```markdown
## API Reference

Documentation of the API...

::: {.readme-only}
### Related Documentation

- [Getting Started](getting-started.md)
- [Examples](examples.md)
- [Back to README](../README.md)
:::
```

### Badges

```markdown
# Project Name

::: {.readme-only}
![Build Status](https://img.shields.io/badge/build-passing-green)
![Version](https://img.shields.io/badge/version-1.0-blue)
:::

## Introduction

Project description...
```

### Installation Notes

```markdown
## Installation

::: {.readme-only}
### Quick Install (for README)

```bash
pip install mypackage
```
:::

Detailed installation instructions for the manual...
```

## Limitations

- Nested readme-only blocks are not supported
- The div must use Pandoc's fenced div syntax
- HTML-style divs are not recognized

## Alternative Syntax

Standard Pandoc div syntax also works:

```markdown
<div class="readme-only">
Content for README only
</div>
```

However, the fenced div syntax (`::: {.readme-only}`) is preferred for better Markdown readability.
