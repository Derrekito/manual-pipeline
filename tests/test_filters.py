"""The filters and the template do what their headers say, run through pandoc as the build runs them."""
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

PIPELINE = Path(__file__).resolve().parents[1]
FILTERS = PIPELINE / 'latex' / 'filters'


def pandoc(markdown, *args, to='latex', env=None):
    """LaTeX (or another format) pandoc makes from the Markdown with the given options."""
    return subprocess.run(['pandoc', '-f', 'markdown', '-t', to, *args], input=markdown,
                          capture_output=True, text=True, check=True, env=env).stdout



FAKE_MMDC = """#!/bin/sh
while [ $# -gt 0 ]; do [ "$1" = -o ] && out=$2; shift; done
printf '%%PDF-1.4\\n' > "$out"
"""


@unittest.skipUnless(shutil.which('pandoc'), 'needs pandoc')
class Mermaid(unittest.TestCase):
    """The Mermaid filter makes its own image directory and keeps a plain picture out of the margin."""

    def setUp(self):
        self.work = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.work)
        self.mmdc = self.work / 'mmdc'
        self.mmdc.write_text(FAKE_MMDC)
        self.mmdc.chmod(0o755)

    def run_filter(self, markdown):
        out = self.work / 'images'
        env = {**os.environ, 'MERMAID_BIN': str(self.mmdc)}
        latex = subprocess.run(
            ['pandoc', '-f', 'markdown', '-t', 'latex', '--filter', str(FILTERS / 'pandoc-mermaid.py'),
             '-M', f'output_dir={out}'],
            input=markdown, capture_output=True, text=True, check=True, env=env, cwd=self.work).stdout
        return latex, out

    def test_image_directory_is_made(self):
        latex, out = self.run_filter('```mermaid\nflowchart LR\n  A --> B\n```\n')
        self.assertNotIn('error', latex.lower())
        self.assertEqual(len(list((out / 'mermaid-images').glob('*.pdf'))), 1)

    def test_plain_picture_has_no_indent(self):
        latex, _ = self.run_filter('```mermaid\nflowchart LR\n  A --> B\n```\n')
        self.assertRegex(latex, r'\\noindent\\includegraphics\[width=\\textwidth\]')

    def test_centred_figure_is_unchanged(self):
        latex, _ = self.run_filter('```{.mermaid center="true"}\nflowchart LR\n  A --> B\n```\n')
        self.assertIn('\\begin{figure}[h]\\centering\n\\includegraphics', latex)


if __name__ == '__main__':
    unittest.main()

