#!/usr/bin/env python3
"""
Pandoc filter for Mermaid PDF images to \\includegraphics.
Handles {.mermaid width="50%" caption="Caption Text" center="true"}, robust and debug-heavy.
"""

import hashlib
import os
import shutil
import subprocess
import sys
from typing import List, Optional

from pandocfilters import (RawBlock, get_caption, get_filename4code,
                           toJSONFilter)

# Define options
MMDC_OPTIONS = {
    "theme": "--theme",
    "width": "--width",  # mmdc pixels
    "height": "--height",
    "background": "--backgroundColor",
    "scale": "--scale",
    "config": "--configFile",
    "cssFile": "--cssFile",
    "puppeteer": "--puppeteerConfigFile",
}

MMDC_FLAGS = {"pdfFit": "--pdfFit", "quiet": "--quiet"}

LATEX_ONLY_OPTIONS = {"width", "scale", "center", "caption"}

MERMAID_BIN = os.path.expanduser(os.environ.get("MERMAID_BIN", "mmdc"))
PUPPETEER_CFG = os.environ.get("PUPPETEER_CFG", None)


def get_file_hash(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def convert_percentage_to_tex(value: str) -> str:
    """Convert '50%' to '0.5\\textwidth', pass through LaTeX values."""
    if not value:
        return value
    if value.endswith("%"):
        try:
            percentage = float(value.strip("%")) / 100
            return f"{percentage}\\textwidth"
        except ValueError:
            return value
    return value


def mermaid(key: str, value: List, format_: str, meta: dict) -> Optional[dict]:
    sys.stderr.write(f"DEBUG: Node - Key: {key}, Value: {str(value)[:50]}...\n")
    if key != "CodeBlock":
        sys.stderr.write(f"DEBUG: Not a CodeBlock, got {key}\n")
        return None

    [[ident, classes, keyvals], code] = value
    sys.stderr.write(
        f"DEBUG: CodeBlock - Classes: {classes}, Keyvals: {keyvals}, Code: {code[:50]}...\n"
    )

    if "mermaid" not in classes:
        sys.stderr.write("DEBUG: No 'mermaid' in classes, skipping\n")
        return None

    sys.stderr.write(f"DEBUG: Processing for format: {format_}\n")

    try:
        caption_data, _, keyvals = get_caption(keyvals)
        # Handle caption: string, list of dicts, or None
        if (
            isinstance(caption_data, list)
            and len(caption_data) > 0
            and "c" in caption_data[0]
        ):
            caption = caption_data[0]["c"]
        elif isinstance(caption_data, str):
            caption = caption_data
        else:
            caption = None
        sys.stderr.write(
            f"DEBUG: After get_caption - Caption: {caption}, Keyvals: {keyvals}\n"
        )

        if (
            not isinstance(meta, dict)
            or "output_dir" not in meta
            or "c" not in meta["output_dir"]
        ):
            sys.stderr.write("DEBUG: Invalid meta structure, using fallback\n")
            output_dir = "build/mermaid_images/mermaid-images"
        else:
            output_dir = meta["output_dir"]["c"]

        if not os.path.isdir(output_dir) or not os.access(output_dir, os.W_OK):
            os.makedirs(output_dir, exist_ok=True)
            if not os.access(output_dir, os.W_OK):
                raise OSError(f"Cannot write to {output_dir}")

        cmd = [
            MERMAID_BIN,
            "--outputFormat",
            "pdf",
            "--pdfFit",
            "--cssFile",
            os.environ.get("MERMAID_FILTER_MERMAID_CSS", ""),
        ]
        latex_options = {}
        for k, v in keyvals:
            if k in MMDC_OPTIONS and k not in LATEX_ONLY_OPTIONS:
                cmd.extend([MMDC_OPTIONS[k], v])
            elif k in MMDC_FLAGS and v.lower() in ("true", "yes", "1"):
                cmd.append(MMDC_FLAGS[k])
            elif k in LATEX_ONLY_OPTIONS:
                latex_options[k] = v

        filename = os.path.join(output_dir, get_filename4code("mermaid", code))
        src = filename + ".mmd"
        pdf_dest = filename + ".pdf"
        code_hash = get_file_hash(code)

        hash_file = filename + ".hash"
        should_generate = True
        if os.path.isfile(pdf_dest) and os.path.isfile(hash_file):
            with open(hash_file, "r", encoding="utf-8") as f:
                cached_hash = f.read().strip()
            should_generate = cached_hash != code_hash

        if should_generate:
            with open(src, "w", encoding="utf-8") as f:
                f.write(code)

            cmd.extend(["-i", src, "-o", pdf_dest])
            if "puppeteer" not in [k for k, _ in keyvals]:
                if PUPPETEER_CFG:
                    cmd.extend(["-p", PUPPETEER_CFG])
                if os.path.isfile(".puppeteer.json"):
                    cmd.extend(["-p", ".puppeteer.json"])

            sys.stderr.write(f"DEBUG: Running command: {' '.join(cmd)}\n")
            try:
                result = subprocess.run(cmd, check=True, capture_output=True, text=True)
                sys.stderr.write(f"DEBUG: mmdc stdout: {result.stdout}\n")
                with open(hash_file, "w", encoding="utf-8") as f:
                    f.write(code_hash)
                sys.stderr.write(f"Created PDF {pdf_dest}\n")
            except subprocess.CalledProcessError as e:
                sys.stderr.write(
                    f"Error generating {pdf_dest}: Return code {e.returncode}\n"
                )
                sys.stderr.write(f"Stdout: {e.stdout}\nStderr: {e.stderr}\n")
                error_msg = e.stderr.replace("$", r"\$")
                return RawBlock("latex", "\\textbf{Mermaid error: " + error_msg + "}")
            finally:
                if os.path.isfile(src):
                    os.remove(src)

        width = convert_percentage_to_tex(latex_options.get("width", ""))
        scale = latex_options.get("scale")
        center = latex_options.get("center", "").lower() in ("true", "yes", "1")
        caption = latex_options.get("caption", caption)  # Prefer attribute if set
        if isinstance(caption, list) and len(caption) > 0 and "c" in caption[0]:
            caption = caption[0]["c"]
        sys.stderr.write(
            f"DEBUG: Parsed LaTeX metadata - width: {width}, scale: {scale}, center: {center}, caption: {caption}\n"
        )

        img_options = []
        if width:
            img_options.append(f"width={width}")
        elif scale:
            img_options.append(f"scale={scale}")
        else:
            img_options.append("width=\\textwidth")

        img_cmd = f"\\includegraphics[{', '.join(img_options)}]{{{pdf_dest}}}"

        if center:
            if caption:
                latex_cmd = f"\\begin{{figure}}[h]\\centering\n{img_cmd}\n\\caption{{{caption}}}\n\\end{{figure}}"
            else:
                latex_cmd = (
                    f"\\begin{{figure}}[h]\\centering\n{img_cmd}\n\\end{{figure}}"
                )
        elif caption:
            latex_cmd = f"\\begin{{figure}}[h]\n{img_cmd}\n\\caption{{{caption}}}\n\\end{{figure}}"
        else:
            latex_cmd = img_cmd

        sys.stderr.write(f"DEBUG: Generated LaTeX: {latex_cmd}\n")
        return RawBlock("latex", latex_cmd)

    except (OSError, ValueError, TypeError) as e:
        sys.stderr.write(f"Unexpected error in filter: {str(e)}\n")
        error_msg = str(e).replace("$", r"\$")
        return RawBlock("latex", "\\textbf{Filter error: " + error_msg + "}")


def main():
    """Run the Pandoc filter with Mermaid processing."""
    if not shutil.which(MERMAID_BIN):
        sys.stderr.write(f"Error: Mermaid CLI '{MERMAID_BIN}' not found in PATH.\n")
        sys.exit(1)
    if not os.access(MERMAID_BIN, os.X_OK):
        sys.stderr.write(f"Error: Mermaid CLI '{MERMAID_BIN}' not executable.\n")
        sys.exit(1)

    toJSONFilter(mermaid)


if __name__ == "__main__":
    main()
