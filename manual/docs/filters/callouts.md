# Callouts Filter

The callouts filter turns GitHub-style alerts into coloured boxes in the \ac{PDF}.

## Location

```
latex/filters/callouts.lua
latex/callouts.latex
```

## Syntax

A block quote whose first line is `[!TYPE]` becomes a callout:

```markdown
> [!NOTE]
> Useful information the reader should know.

> [!WARNING] Back up first
> Text after the marker replaces the default title.
```

The five GitHub types each have their own colour and icon:

| Type | Use |
|---|---|
| `NOTE` | Information worth noticing |
| `TIP` | Advice for doing something better |
| `IMPORTANT` | Something the reader must know |
| `WARNING` | Something that needs attention now |
| `CAUTION` | A risky or harmful outcome |

Other common names take the nearest style and keep their own word as the
title: `NOTES` and `INFO` are notes, `HINT` is a tip, `DANGER` and `ERROR`
are cautions. Any other `[!WORD]` is boxed as a note titled with the word.
Obsidian's fold marks (`[!NOTE]-`, `[!NOTE]+`) are dropped.

## Output

For \ac{LaTeX}, the filter writes a `callout` tcolorbox environment
(defined in `callouts.latex`) that breaks across pages. Code, lists and
tables inside the box are handled by the later filters as usual. For
\ac{DOCX} and other formats the callout becomes a `callout callout-<type>`
div with a bold title.

A block quote without a marker stays an ordinary quote.
