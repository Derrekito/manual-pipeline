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


@unittest.skipUnless(shutil.which('pandoc'), 'needs pandoc')
class TableWidths(unittest.TestCase):
    """Tables without widths get wrapping columns; tables with widths keep theirs."""

    lua = ['--lua-filter', str(FILTERS / 'table-widths.lua')]

    def widths(self, latex):
        return [float(w) for w in re.findall(r'\\real\{([0-9.]+)\}', latex)]

    def test_wide_table_gets_wrapping_columns(self):
        latex = pandoc('| Path | What it is |\n|---|---|\n| `a/b.sh` | a script that does one thing at length |\n',
                       *self.lua, '-M', 'table-fit-chars=30')
        widths = self.widths(latex)
        self.assertEqual(len(widths), 2)
        self.assertAlmostEqual(sum(widths), 1, places=3)
        self.assertLess(widths[0], widths[1])

    def test_table_that_fits_stays_compact(self):
        source = '| Command | Description |\n|---|---|\n| `make pdf` | Generate PDF |\n'
        self.assertEqual(pandoc(source, *self.lua), pandoc(source))

    def test_fit_limit_comes_from_metadata(self):
        source = '| Command | Description |\n|---|---|\n| `make pdf` | Generate PDF |\n'
        self.assertEqual(len(self.widths(pandoc(source, *self.lua, '-M', 'table-fit-chars=10'))), 2)

    def test_without_the_filter_columns_do_not_wrap(self):
        latex = pandoc('| a | b |\n|---|---|\n| x | y |\n')
        self.assertIn('{@{}ll@{}}', latex)

    def test_column_is_never_narrower_than_its_longest_word(self):
        long_cell = 'word ' * 12
        latex = pandoc(f'| Name | Text |\n|---|---|\n| supercalifragilistic | {long_cell} |\n', *self.lua,
                       '-M', 'table-fit-chars=30')
        name, text = self.widths(latex)
        self.assertGreaterEqual(name / text, 22 / 45 - 0.01)

    def test_table_with_widths_is_left_alone(self):
        source = ('+------+----------------------------------------+\n'
                  '| a    | b                                      |\n'
                  '+======+========================================+\n'
                  '| x    | y                                      |\n'
                  '+------+----------------------------------------+\n')
        self.assertEqual(pandoc(source, *self.lua), pandoc(source))


@unittest.skipUnless(shutil.which('pandoc'), 'needs pandoc')
class InlineCodeBreaks(unittest.TestCase):
    """Inline code can break after separators and keeps its special characters."""

    lua = ['--lua-filter', str(FILTERS / 'inline-code-breaks.lua')]

    def test_breaks_after_separators(self):
        latex = pandoc('Run `lab/build_one.sh --x=1,2` now.\n', *self.lua)
        self.assertIn(r'{\codefont\footnotesize lab/\allowbreak{}build\_\allowbreak{}one.\allowbreak{}sh '
                      r'-\allowbreak{}-\allowbreak{}x=\allowbreak{}1,\allowbreak{}2}', latex)

    def test_special_characters_are_escaped(self):
        latex = pandoc('`a\\b{c}$d&e#f^g%h~i`\n', *self.lua)
        self.assertIn(r'a\textbackslash{}b\{c\}\$d\&e\#f\textasciicircum{}g\%h\textasciitilde{}i', latex)

    def test_code_with_a_language_is_left_for_minted(self):
        latex = pandoc('`print(1)`{.python}\n', *self.lua)
        self.assertNotIn('codefont', latex)

    def test_other_formats_are_left_alone(self):
        self.assertIn('<code>a/b</code>', pandoc('`a/b`\n', *self.lua, to='html'))


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


@unittest.skipUnless(shutil.which('pandoc'), 'needs pandoc')
class Template(unittest.TestCase):
    """A caller's header settings land last before the document starts."""

    def test_header_includes_follow_the_pipeline_settings(self):
        latex = pandoc('Body.\n', '--template', str(PIPELINE / 'latex' / 'template.latex'),
                       '-V', 'header-includes=\\newcommand{\\fromcaller}{}', '-M', 'title=T')
        caller = latex.index('\\newcommand{\\fromcaller}{}')
        self.assertGreater(caller, latex.index('\\setkeys{Gin}'))
        self.assertGreater(caller, latex.index('\\captionsetup[figure]'))
        self.assertLess(caller, latex.index('\\begin{document}'))

    def test_without_header_includes_nothing_is_added(self):
        latex = pandoc('Body.\n', '--template', str(PIPELINE / 'latex' / 'template.latex'), '-M', 'title=T')
        self.assertNotIn('$for', latex)
        self.assertNotIn('$header-includes$', latex)
        self.assertNotIn('fromcaller', latex)


class Chain(unittest.TestCase):
    """The PDF build runs the new filters, in the order they need."""

    def test_filter_order(self):
        script = (PIPELINE / 'scripts' / 'create_pdf.sh').read_text()
        pdf = next(line for line in script.splitlines() if 'pandoc_cmd="pandoc' in line and 'template' in line)
        order = [pdf.index(name) for name in
                 ['table-widths.lua', 'inline-code-breaks.lua', 'pandoc-mermaid.py', 'pandoc-minted.py']]
        self.assertEqual(order, sorted(order))


if __name__ == '__main__':
    unittest.main()
