#!/usr/bin/env python3
"""
Pandoc filter to inject logo LaTeX blocks based on logos.yaml configuration.

Reads logos.yaml from PIPELINE_DIR and generates LaTeX logo blocks
for each logo key that is set to true in the document metadata.
"""

import os
import sys
import yaml
from pathlib import Path


def load_logo_config():
    """Load logos.yaml from PIPELINE_DIR."""
    pipeline_dir = os.environ.get('PIPELINE_DIR', os.getcwd())
    logo_config_path = Path(pipeline_dir) / 'logos.yaml'

    if not logo_config_path.exists():
        # No logos.yaml = no logos, silently continue
        return []

    with open(logo_config_path, 'r') as f:
        config = yaml.safe_load(f)
        return config.get('logos', [])


def generate_logo_latex(logos_to_render):
    """Generate LaTeX code for rendering logos."""
    if not logos_to_render:
        return ""

    latex_blocks = []
    latex_blocks.append("  \\vfill")
    latex_blocks.append("  \\hfill")

    for logo in logos_to_render:
        latex_blocks.append(
            f"  \\includegraphics[width={logo['width']}]{{{logo['file']}}}"
        )
        latex_blocks.append("  \\hfill")

    latex_blocks.append("  \\break")

    return "\n".join(latex_blocks)


def main():
    """Pandoc metadata filter to inject logo configuration."""
    import json

    # Read pandoc JSON from stdin
    doc = json.load(sys.stdin)

    # Get metadata
    metadata = doc.get('meta', {})

    # Load logo configuration
    logo_configs = load_logo_config()

    # Find which logos are enabled in frontmatter
    logos_to_render = []
    for logo in logo_configs:
        key = logo['key']
        # Check if this logo key is set to true in metadata
        if key in metadata:
            meta_value = metadata[key]
            # Pandoc metadata booleans are {t: 'MetaBool', c: true/false}
            if meta_value.get('t') == 'MetaBool' and meta_value.get('c'):
                logos_to_render.append(logo)

    # Generate LaTeX and inject into metadata as raw LaTeX
    if logos_to_render:
        logo_latex = generate_logo_latex(logos_to_render)
        metadata['logo-block'] = {
            't': 'MetaInlines',
            'c': [{
                't': 'RawInline',
                'c': ['tex', logo_latex]
            }]
        }

    # Write modified doc to stdout
    json.dump(doc, sys.stdout)


if __name__ == '__main__':
    main()
