# Include Files Filter

The include-files filter enables modular documentation by allowing external Markdown files to be incorporated into the main document during the Pandoc conversion process.

## Location

```
latex/filters/include-files.lua
```

## Purpose

Large documents benefit from being split into multiple files. This filter processes include directives and replaces them with the content of referenced files, enabling:

- Reuse of documentation across multiple outputs
- Easier maintenance of large documents
- Logical organization by topic
- Collaborative editing of separate sections

## Syntax

### Basic Include

```markdown
!include path/to/file.md
```

or

```markdown
{{include path/to/file.md}}
```

Includes the file content as-is, preserving heading levels.

### Headless Include

```markdown
!include-headless path/to/file.md
```

Includes the file, strips its first H1 heading, and shifts remaining headings down one level. Use this when the included file has its own title that would conflict with the section heading in the master document.

### Shifted Include

```markdown
!include-shift path/to/file.md
!include-shift:2 path/to/file.md
```

Includes the file and shifts all headings by the specified amount (default: 1). Useful when including a standalone document as a subsection.

## Path Resolution

Paths are resolved relative to the input document's directory:

```{.nobreak}
manual/
├── yourproject-manual.md     # Master document
├── docs/
│   ├── intro.md              # Include as: docs/intro.md
│   └── api/
│       └── reference.md      # Include as: docs/api/reference.md
└── ../README.md              # Include as: ../README.md
```

## Processing

The filter:

1. Reads the referenced file
2. Strips \ac{YAML} frontmatter from included files
3. Parses content as Markdown
4. Applies transformations (heading shift, H1 strip)
5. Prefixes heading IDs to avoid duplicates
6. Returns the parsed blocks

## Heading ID Prefixing

To prevent duplicate anchor IDs when multiple files define similar headings, the filter automatically prefixes heading IDs with the source filename:

| Source File | Heading | Generated ID |
|-------------|---------|--------------|
| `intro.md` | `# Overview` | `intro-overview` |
| `api.md` | `# Overview` | `api-overview` |

## Examples

### Master Document Structure

```markdown
---
title: "Complete Manual"
---

# Introduction

!include-headless docs/intro.md

# API Reference

!include-headless docs/api.md

# Appendix

!include docs/appendix.md
```

### Including README

```markdown
# Project Overview

!include-headless ../README.md
```

The project README can serve as the introduction without duplicating content.

### Nested Includes

Included files can themselves contain include directives:

```markdown
# Services

!include-headless services/overview.md

## DUT Service

!include-headless services/dut.md

## MQTT Service

!include-headless services/mqtt.md
```

## Error Handling

If a file cannot be opened, the filter:

1. Writes a warning to stderr
2. Leaves the include directive unchanged
3. Continues processing other directives

Check the Pandoc output log for missing file warnings.

## Limitations

- Circular includes are not detected and will cause infinite loops
- Binary files cannot be included
- Relative paths must be valid from the master document location
