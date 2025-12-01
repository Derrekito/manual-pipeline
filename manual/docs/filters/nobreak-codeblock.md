# No-Break Codeblock Filter

The nobreak-codeblock filter prevents code blocks from breaking across pages, keeping related code together for readability.

## Location

```
latex/filters/nobreak-codeblock.lua
```

## Purpose

Page breaks in the middle of code blocks reduce readability. This filter marks code blocks that should remain on a single page, using \ac{LaTeX}'s minipage environment.

## Syntax

Add the `.nobreak` class to a fenced code block:

````markdown
```{.python .nobreak}
def complete_function():
    """This block will not break across pages."""
    step_one()
    step_two()
    step_three()
    return result
```
````

Or for generic code:

````markdown
```{.nobreak}
directory/
├── file1.txt
├── file2.txt
└── subdirectory/
    └── file3.txt
```
````

## Processing

The filter transforms marked code blocks to use a non-breaking minted environment in \ac{LaTeX}:

**Input** (Markdown):
````markdown
```{.bash .nobreak}
#!/bin/bash
echo "Hello"
```
````

**Output** (\ac{LaTeX}):
```text
\begin{mymintednobreak}{bash}
#!/bin/bash
echo "Hello"
\end{mymintednobreak}
```

The `mymintednobreak` environment is defined in `codeblocks.latex` and wraps the code in a minipage.

## When to Use

Apply `.nobreak` to:

- Short, complete code examples (under ~30 lines)
- Directory structures
- Configuration snippets
- Function definitions that should be seen as a unit

## When Not to Use

Avoid `.nobreak` for:

- Long code blocks that exceed page height
- Code that naturally has logical break points
- Output logs or data that can be split

## Limitations

- If the code block exceeds page height, it will overflow
- The minipage may cause awkward spacing before/after
- Not all syntax highlighting features work identically in minipage

## Example

````markdown
## Configuration File

The configuration uses YAML format:

```{.yaml .nobreak}
server:
  host: localhost
  port: 8080

database:
  driver: postgresql
  name: myapp
```

This keeps the complete configuration visible on one page.
````

## Related Filters

- **minted**: Handles syntax highlighting
- **notebook-toggle**: Controls code visibility
