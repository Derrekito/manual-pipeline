# Glossary

This glossary defines terms used throughout the Manual Pipeline documentation.

## A

**Acronym**
: An abbreviation formed from the initial letters of a phrase. In Manual Pipeline, acronyms are managed by the \ac{LaTeX} `acronym` package and automatically expand on first use.

## B

**Biber**
: A bibliography processor used with BibLaTeX to generate reference lists from `.bib` files.

**BibLaTeX**
: A \ac{LaTeX} package for bibliography management, more flexible than traditional BibTeX.

## C

**Chromium**
: Open-source web browser used by Mermaid \ac{CLI} for headless diagram rendering.

## D

**DOCX**
: Microsoft Word document format, an alternative output format supported by Manual Pipeline.

## F

**Fenced Code Block**
: A code block delimited by triple backticks (```) in Markdown, with optional language specification.

**Fenced Div**
: A block-level container in Pandoc Markdown delimited by `:::`, used for applying classes to content.

**Fira Code**
: A monospaced programming font with ligature support, used for code blocks.

**Filter**
: A program that transforms Pandoc's internal document representation. Manual Pipeline uses Lua and Python filters.

**Frontmatter**
: Metadata at the beginning of a document, typically in \ac{YAML} format, specifying title, author, and configuration options.

## L

**latexmk**
: A Perl script that automates \ac{LaTeX} document compilation, running the required number of passes for cross-references.

**LuaLaTeX**
: A \ac{LaTeX} engine with built-in Lua scripting and native Unicode support, used by Manual Pipeline for \ac{PDF} generation.

## M

**Makefile**
: A build automation file that defines targets and dependencies. Projects include Manual Pipeline's `Makefile.include`.

**Mermaid**
: A JavaScript-based diagramming tool that renders text definitions into flowcharts, sequence diagrams, and other visualizations.

**Minted**
: A \ac{LaTeX} package for syntax highlighting using the Pygments library.

**mmdc**
: The Mermaid command-line interface executable used to render diagrams.

## N

**Node.js**
: JavaScript runtime required for Mermaid diagram rendering.

**npm**
: Node Package Manager, used to install Mermaid \ac{CLI}.

## P

**Pandoc**
: Universal document converter that transforms Markdown to \ac{LaTeX}, \ac{HTML}, \ac{DOCX}, and other formats.

**Pandoc Filter**
: A program that processes Pandoc's \ac{AST} to transform content. Manual Pipeline includes both Lua and Python filters.

**PDF**
: Portable Document Format, the primary output format of Manual Pipeline.

**Preamble**
: The portion of a \ac{LaTeX} document before `\begin{document}`, containing package imports and configuration.

**Preprocessing**
: Transformation of source files before main processing. Manual Pipeline preprocesses Markdown to protect acronym commands.

**Puppeteer**
: Node.js library for controlling headless Chrome/Chromium, used by Mermaid for rendering.

**Pygments**
: Python syntax highlighting library used by minted for code coloring.

## S

**Shell Escape**
: \ac{LaTeX} option allowing external program execution, required by minted for Pygments.

## T

**Template**
: A file containing placeholders for variable substitution. Manual Pipeline uses Pandoc \ac{LaTeX} templates.

**TeX Live**
: A comprehensive \ac{LaTeX} distribution including LuaLaTeX, latexmk, and required packages.

**TikZ**
: \ac{LaTeX} package for creating graphics programmatically.

**TOC**
: Table of Contents, automatically generated from document headings.

## U

**Unicode**
: Character encoding standard supporting international text and symbols. LuaLaTeX provides full Unicode support.

## V

**venv**
: Python virtual environment for isolated package installation.

## Y

**YAML**
: \ac{YAML} Ain't Markup Language, a human-readable data format used for Pandoc frontmatter and configuration files.
