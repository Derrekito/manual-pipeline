# Markdown Links to Refs Filter

The md-links-to-refs filter converts Markdown-style links to \ac{LaTeX} cross-references where appropriate, enabling proper page number references in \ac{PDF} output.

## Location

```
latex/filters/md-links-to-refs.lua
```

## Purpose

Markdown links work well for HTML output but don't translate naturally to \ac{PDF}:

- External links become clickable hyperlinks (handled by hyperref)
- Internal links to headings should become "see page X" or "see Section Y"

This filter bridges the gap by converting internal links to \ac{LaTeX} reference commands.

## Processing

The filter examines link targets and transforms them:

| Link Type | Input | Output |
|-----------|-------|--------|
| External URL | `[text](https://...)` | Hyperlink (unchanged) |
| Internal anchor | `[text](#section-id)` | `\hyperref[section-id]{text}` |
| File reference | `[text](file.md)` | Stripped (text only) |
| File with anchor | `[text](file.md#id)` | `\hyperref[id]{text}` |

## Examples

### Internal Section Links

**Markdown**:
```markdown
See the [Configuration](#configuration) section for details.
```

**Result in \ac{PDF}**: "See the Configuration section for details." with clickable link to that section.

### Cross-File References

**Markdown**:
```markdown
Refer to the [API documentation](api.md#endpoints) for endpoint details.
```

**Result in \ac{PDF}**: "Refer to the API documentation for endpoint details." with link to the endpoints section.

### External Links

**Markdown**:
```markdown
Visit [GitHub](https://github.com) for more information.
```

**Result in \ac{PDF}**: Clickable "GitHub" hyperlink.

## Heading ID Generation

Pandoc generates heading IDs automatically:

| Heading | Generated ID |
|---------|--------------|
| `# Configuration` | `configuration` |
| `## API Reference` | `api-reference` |
| `### Quick Start Guide` | `quick-start-guide` |

You can also specify custom IDs:

```markdown
## Configuration {#config}
```

## Explicit Anchors

For non-heading targets, add explicit anchors:

```markdown
::: {#important-note}
This content can be linked to.
:::

See the [important note](#important-note) above.
```

## Limitations

- Links to specific lines in code blocks are not supported
- File-only references (without anchors) lose their links
- Anchor IDs must match exactly (case-sensitive)

## Related Features

- **hyperref package**: Handles \ac{URL} hyperlinking
- **cleveref package**: Smart reference formatting
- **include-files filter**: Prefixes IDs to avoid conflicts
