# Templates

The pipeline uses a modular \ac{LaTeX} template system. The main template includes component files for preamble, fonts, code blocks, styles, and title page. This section documents each component.

## Template Structure

```{.nobreak}
latex/
├── template.latex     # Main Pandoc template
├── preamble.latex     # Package imports and fixes
├── codeblocks.latex   # Minted configuration
├── fonts.latex        # Font setup for LuaLaTeX
├── styles.latex       # Document formatting
└── titlepage.latex    # Custom title page
```

## template.latex

The main template that Pandoc processes. It uses Pandoc's template syntax for variable substitution.

### Structure

```text
\documentclass[11pt]{article}
${ preamble() }
${ codeblocks() }
${ fonts() }
${ styles() }

$if(bibfile)$
\addbibresource{$bibfile$}
$endif$

\begin{document}
$if(title)$
${titlepage()}
$endif$

\pagenumbering{roman}
$if(toc)$
\tableofcontents
\newpage
$endif$

$if(acronyms)$
\section*{List of Acronyms and Abbreviations}
\input{./latex/acronyms.tex}
\newpage
$endif$

\pagenumbering{arabic}
$body$

$if(bibfile)$
\printbibliography
$endif$
\end{document}
```

### Pandoc Variables

| Variable | Type | Description |
|----------|------|-------------|
| `$title$` | string | Document title |
| `$subtitle$` | string | Document subtitle |
| `$author$` | list | Author name(s) |
| `$date$` | string | Document date |
| `$toc$` | boolean | Include table of contents |
| `$acronyms$` | boolean | Include acronym list |
| `$bibfile$` | string | Bibliography file path |
| `$body$` | content | Converted document body |

## preamble.latex

Core package imports and compatibility fixes.

### Key Packages

| Package | Purpose |
|---------|---------|
| `geometry` | Page layout (1" margins) |
| `acronym` | Acronym management |
| `minted` | Syntax highlighting |
| `hyperref` | Clickable links and \ac{PDF} metadata |
| `cleveref` | Smart cross-references |
| `biblatex` | Bibliography support |
| `tikz` | Diagram drawing |
| `fontspec` | Font selection for LuaLaTeX |

### TexLive 2025 Fix

The preamble includes a fix for the acronym + cleveref conflict:

```text
\makeatletter
\AtBeginDocument{%
  \def\ltx@label#1{\cref@label{#1}}%
  \def\label@in@display@noarg#1{\cref@old@label@in@display{#1}}%
}
\makeatother
```

### TikZ Styles

Predefined styles for system diagrams:

| Style | Description |
|-------|-------------|
| `block` | Blue rounded rectangle |
| `network` | Network node with icon |
| `icon` | Large icon placeholder |
| `data` | Orange trapezoid for data stores |
| `arrow_data_twoway` | Blue dashed bidirectional arrow |
| `arrow_data_oneway` | Blue dashed unidirectional arrow |
| `arrow_power` | Red power connection |
| `arrow_beam` | Black dashed beam path |

## codeblocks.latex

Minted environment configuration for syntax highlighting.

### Terminal Environment

```text
\newminted{text}{
    linenos=true,
    breaklines=true,
    frame=single,
    fontsize=\small
}
```

### No-Break Environment

For code blocks that should not break across pages:

```text
\newenvironment{mymintednobreak}[1]{%
    \VerbatimEnvironment
    \begin{minipage}{\linewidth}
    \begin{minted}[linenos,breaklines,frame=single,fontsize=\small]{#1}
}{%
    \end{minted}
    \end{minipage}
}
```

## fonts.latex

Font configuration for LuaLaTeX.

### Default Fonts

```text
\setmainfont{TeX Gyre Termes}
\setmonofont{Fira Code}[
    Contextuals=Alternate,
    Scale=0.9
]
```

### Emoji Support

```text
\newfontfamily\emojifont{Noto Color Emoji}[Renderer=Harfbuzz]
\newunicodechar{✓}{{\emojifont ✓}}
\newunicodechar{✗}{{\emojifont ✗}}
```

### Unicode Characters

Common Unicode characters are mapped to \ac{LaTeX} equivalents:

| Character | Code | Description |
|-----------|------|-------------|
| → | U+2192 | Right arrow |
| ≥ | U+2265 | Greater or equal |
| ≤ | U+2264 | Less or equal |
| ± | U+00B1 | Plus-minus |

## styles.latex

Document formatting and layout.

### Spacing

```text
\setstretch{1.15}           % Line spacing
\setlength{\parskip}{0.5em} % Paragraph spacing
\setlength{\parindent}{0pt} % No paragraph indent
```

### Section Formatting

```text
\titleformat{\section}
    {\normalfont\Large\bfseries}
    {\thesection}{1em}{}
```

### List Formatting

```text
\setlist[itemize]{noitemsep, topsep=0pt}
\setlist[enumerate]{noitemsep, topsep=0pt}
```

## titlepage.latex

Custom title page with optional logos and metadata.

### Logo Placement

The title page supports three logo positions:

- Government logo (left side)
- Company logo (right side)
- University logo (center bottom)

### Conditional Rendering

```text
$if(govlogo)$
\includegraphics[height=1in]{USSF_logo.pdf}
$endif$
```

### Metadata Display

```text
$if(version)$
\textbf{Version:} $version$
$endif$

$if(disclaimer)$
\textit{$disclaimer$}
$endif$
```

## Customization

### Per-Project Overrides

Projects can override template components by creating local versions:

1. Copy the template file to your project's `latex/` directory
2. Modify as needed
3. The pipeline uses project files when present

### Adding Custom Packages

Add to your project's `latex/custom-preamble.tex`:

```text
\usepackage{mypackage}
\newcommand{\mycmd}[1]{...}
```

Then include in your template:

```text
\input{latex/custom-preamble.tex}
```

::: {.readme-only}
## Related Documentation

- [Architecture](architecture.md)
- [Filter Documentation](filters/)
:::
