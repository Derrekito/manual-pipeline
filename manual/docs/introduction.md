# Introduction

Manual Pipeline is a centralized Pandoc + \ac{LaTeX} documentation pipeline for generating professional \ac{PDF} and \ac{DOCX} manuals from Markdown source files. It provides a reusable infrastructure that multiple projects can integrate to automate their documentation workflows.

## Purpose

Technical documentation often requires:

- Professional typesetting with proper fonts, headers, and footers
- Syntax-highlighted code blocks with line numbers
- Diagrams rendered from text-based descriptions
- Acronym management with automatic expansion on first use
- Table of contents and cross-references
- Bibliography support

Manual Pipeline addresses these needs through a combination of Pandoc filters, \ac{LaTeX} templates, and build automation. Projects integrate the pipeline with a minimal Makefile and focus on writing content in Markdown.

## Features

The pipeline provides:

- **LuaLaTeX \ac{PDF} Generation**: Full Unicode and emoji support via the LuaLaTeX engine
- **Acronym Support**: Commands like `\ac{}`, `\Ac{}`, `\acf{}`, `\acs{}` for automatic acronym expansion
- **Mermaid Diagrams**: Flowcharts, sequence diagrams, and state machines rendered from text
- **Code Highlighting**: Syntax highlighting with minted and Pygments for 100+ languages
- **Algorithm/Pseudocode**: Support for algorithm and pseudocode environments
- **TikZ Diagrams**: Predefined styles for system architecture diagrams
- **Auto-Setup**: Automatic dependency installation on first build
- **TexLive 2025 Compatibility**: Fixes for known issues in recent TeX distributions

## Design Philosophy

The pipeline follows several guiding principles:

1. **Separation of Concerns**: Build logic lives in the pipeline; content lives in projects
2. **Minimal Per-Project Configuration**: Projects need only a 3-line Makefile
3. **Documentation as Code**: All sources tracked in version control
4. **Reproducible Builds**: Same input always produces same output
5. **Progressive Enhancement**: Core features work without optional dependencies

## Projects Using This Pipeline

The following projects generate their documentation with Manual Pipeline:

- RADCaST (Radiation Anomaly Detection, Capture, and Streaming Telemetry)
- SPARCL (Multi-Architecture Benchmarking Suite)
- Cache March Test (SRAM SEU/SET Detection)
- YoctoForge (Embedded Linux Build System)

::: {.readme-only}
## Related Documentation

- [Quick Start](quick-start.md)
- [Architecture](architecture.md)
- [Integration Guide](integration.md)
:::
