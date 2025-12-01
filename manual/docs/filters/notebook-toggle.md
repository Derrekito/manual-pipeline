# Notebook Toggle Filter

The notebook-toggle filter controls visibility of code blocks and outputs based on \ac{YAML} frontmatter settings. This enables generating documentation with or without code examples from the same source.

## Location

```
latex/filters/notebook-toggle.lua
```

## Purpose

Some documents serve dual purposes:

- Technical tutorials with full code examples
- Executive summaries without implementation details
- Printed manuals where code blocks consume space

This filter allows toggling code visibility without maintaining separate documents.

## Configuration

Set the `notebook` variable in \ac{YAML} frontmatter:

```yaml
---
title: "Document"
notebook: true   # Show code blocks (default)
---
```

```yaml
---
title: "Document"
notebook: false  # Hide code blocks
---
```

## Behavior

When `notebook: false`:

| Element | Behavior |
|---------|----------|
| Code blocks | Removed |
| Inline code | Preserved |
| Code output sections | Removed |
| Regular paragraphs | Preserved |

When `notebook: true` (default):

All content is preserved.

## Use Cases

### Dual-Purpose Documentation

```yaml
---
title: "API Guide"
notebook: true
---

# Getting Started

Install the package:

```python
pip install mypackage
```

Import and use:

```python
import mypackage
result = mypackage.process(data)
```
```

Generate with code:
```bash
make pdf
```

Generate without code (modify frontmatter or use variable override):
```bash
pandoc -V notebook=false ...
```

### Print vs. Digital

Create print-friendly versions by disabling code blocks, which often don't format well on paper.

## Limitations

- Applies to all code blocks uniformly
- Cannot selectively show/hide specific blocks
- Inline code (backtick-wrapped) is always preserved

## Related Filters

- **nobreak-codeblock**: Controls page breaking, not visibility
- **minted**: Handles syntax highlighting for visible blocks
