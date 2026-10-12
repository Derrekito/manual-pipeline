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


def pandoc(markdown, *args, to='latex', env=None, reader='markdown'):
    """LaTeX (or another format) pandoc makes from the Markdown with the given options."""
    return subprocess.run(['pandoc', '-f', reader, '-t', to, *args], input=markdown,
                          capture_output=True, text=True, check=True, env=env).stdout


WIDE = ('| Variable | Default | Meaning |\n|---|---|---|\n'
        '| STAGE_BOOT_MANIFEST | /var/lib/keylime/secure/payload | Where the agent writes the manifest |\n'
        '| STAGE_BOOT_DEADLINE | 300 | Seconds to wait for the manifest |\n')


@unittest.skipUnless(shutil.which('pandoc'), 'needs pandoc')
class TableWidths(unittest.TestCase):
    """Tables without widths keep natural columns to be scaled, or wrap when scaling would go too far.
    That they are marked for scaling is tested through table-scale.lua below."""

    lua = ['--lua-filter', str(FILTERS / 'table-widths.lua')]

    def convert(self, markdown, *args, to='latex'):
        """Read as GitHub Markdown, which leaves pipe tables unsized; pandoc's own
        reader sizes any pipe table whose source lines are long."""
        return pandoc(markdown, *self.lua, *args, to=to, reader='gfm')

    def widths(self, latex):
        return [float(w) for w in re.findall(r'\\real\{([0-9.]+)\}', latex)]

    def test_table_that_can_scale_keeps_its_natural_columns(self):
        self.assertEqual(self.widths(self.convert(WIDE)), [])

    def test_table_too_wide_to_scale_gets_wrapping_columns(self):
        widths = self.widths(self.convert(WIDE, '-M', 'table-fit-chars=40'))
        self.assertEqual(len(widths), 3)
        self.assertAlmostEqual(sum(widths), 1, places=3)

    def test_minimum_scale_comes_from_metadata(self):
        self.assertEqual(self.widths(self.convert(WIDE, '-M', 'table-fit-chars=40', '-M', 'table-min-scale=0.3')), [])

    def test_column_is_never_narrower_than_its_longest_word(self):
        long_cell = 'word ' * 12
        latex = pandoc(f'| Name | Text |\n|---|---|\n| supercalifragilistic | {long_cell} |\n', *self.lua,
                       '-M', 'table-fit-chars=30')
        name, text = self.widths(latex)
        self.assertGreaterEqual(name / text, 22 / 45 - 0.01)

    def test_short_column_keeps_its_word_beside_long_ones(self):
        long = 'a cell with a good deal of text in it, more than the cap allows for'
        source = ('| Certificate | In | Signs | Expires | Replaced by |\n|---|---|---|---|---|\n'
                  f'| {long} | KEK | {long} | 24 June 2026 | {long} |\n')
        widths = self.widths(self.convert(source, '-M', 'table-fit-chars=60'))
        self.assertAlmostEqual(sum(widths), 1, places=3)
        self.assertGreaterEqual(widths[1], (3 + 2) / 60 - 0.001)

    def test_table_with_widths_is_left_alone(self):
        source = ('+------+----------------------------------------+\n'
                  '| a    | b                                      |\n'
                  '+======+========================================+\n'
                  '| x    | y                                      |\n'
                  '+------+----------------------------------------+\n')
        self.assertEqual(pandoc(source, *self.lua), pandoc(source))


@unittest.skipUnless(shutil.which('pandoc'), 'needs pandoc')
class TableScale(unittest.TestCase):
    """A marked table is measured as a tabular and set as a longtable at the size that fits."""

    lua = ['--lua-filter', str(FILTERS / 'table-widths.lua'), '--lua-filter', str(FILTERS / 'table-scale.lua')]

    def convert(self, markdown, *args, to='latex'):
        """Read as GitHub Markdown, which leaves pipe tables unsized; pandoc's own
        reader sizes any pipe table whose source lines are long."""
        return pandoc(markdown, *self.lua, *args, to=to, reader='gfm')

    def test_measured_three_times_then_set_as_a_longtable(self):
        latex = self.convert(WIDE)
        self.assertEqual(latex.count('\\begin{lrbox}{\\tablefitbox}'), 3)
        self.assertEqual(latex.count('\\tablefitscale\n'), 3)
        self.assertIn('\\begin{longtable}', latex)
        self.assertLess(latex.rindex('\\tablefitscale'), latex.index('\\begin{longtable}'))

    def test_measuring_tabular_has_header_rows_then_rule(self):
        latex = self.convert(WIDE)
        tabular = latex[latex.index('\\begin{tabular}'):latex.index('\\end{tabular}')]
        self.assertNotIn('\\endhead', tabular)
        self.assertNotIn('\n\n', tabular)
        self.assertLess(tabular.index('Variable'), tabular.index('STAGE'))
        self.assertLess(tabular.index('DEADLINE'), tabular.index('\\bottomrule'))

    def test_caption_stays_with_the_longtable_only(self):
        latex = pandoc('Table: Settings\n\n| Name | Value |\n|---|---|\n| deadline | 300 seconds |\n',
                       *self.lua, '-M', 'table-fit-chars=10', '-M', 'table-min-scale=0.1')
        tabular = latex[latex.index('\\begin{tabular}'):latex.index('\\end{tabular}')]
        self.assertNotIn('caption', tabular)
        self.assertIn('\\caption{Settings}', latex[latex.index('\\begin{longtable}'):])

    def test_unmarked_tables_and_other_formats_are_left_alone(self):
        wrapped = ['-M', 'table-fit-chars=40']
        self.assertNotIn('lrbox', self.convert(WIDE, *wrapped))
        self.assertIn('<table>', self.convert(WIDE, to='html'))

    def test_words_that_cannot_sit_side_by_side_shrink_the_font(self):
        source = ('| Alpha | Beta | Gamma |\n|---|---|---|\n'
                  '| supercalifragilistic | expialidocious-words | antidisestablishment |\n')
        latex = self.convert(source, '-M', 'table-fit-chars=40', '-M', 'table-min-scale=0.9')
        match = re.search(r'\\tablescaleby\{([0-9.]+)\}', latex)
        self.assertIsNotNone(match)
        self.assertAlmostEqual(float(match.group(1)), 40 / 66, places=2)
        self.assertLess(match.start(), latex.index('\\begin{longtable}'))
        self.assertNotIn('lrbox', latex)

    @unittest.skipUnless(shutil.which('lualatex'), 'needs lualatex')
    def test_wide_table_fits_the_line(self):
        work = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, work)
        (work / 't.tex').write_text(self.convert('Before.\n\n' + WIDE + '\nAfter.\n', '-s', '-V', 'tables'))
        for _ in range(2):  # longtable settles its columns on the second run
            subprocess.run(['lualatex', '-interaction=nonstopmode', '-halt-on-error', 't.tex'],
                           cwd=work, capture_output=True, check=True, timeout=300)
        log = (work / 't.log').read_text(errors='replace')
        self.assertNotIn('Overfull \\hbox', log)


@unittest.skipUnless(shutil.which('pandoc'), 'needs pandoc')
class InlineCodeBreaks(unittest.TestCase):
    """Inline code can break after separators and keeps its special characters."""

    lua = ['--lua-filter', str(FILTERS / 'inline-code-breaks.lua')]

    def test_breaks_after_separators(self):
        latex = pandoc('Run `lab/build_one.sh --x=1,2` now.\n', *self.lua)
        self.assertIn(r'\breakablecode{lab/\allowbreak{}build\_\allowbreak{}one.\allowbreak{}sh '
                      r'-\allowbreak{}-\allowbreak{}x=\allowbreak{}1,\allowbreak{}2}', latex)

    def test_special_characters_are_escaped(self):
        latex = pandoc('`a\\b{c}$d&e#f^g%h~i`\n', *self.lua)
        self.assertIn(r'a\textbackslash{}b\{c\}\$d\&e\#f\textasciicircum{}g\%h\textasciitilde{}i', latex)

    def test_code_with_a_language_is_left_for_minted(self):
        latex = pandoc('`print(1)`{.python}\n', *self.lua)
        self.assertNotIn('breakablecode', latex)

    def test_other_formats_are_left_alone(self):
        self.assertIn('<code>a/b</code>', pandoc('`a/b`\n', *self.lua, to='html'))

    def test_size_follows_the_text_around_it(self):
        latex = (PIPELINE / 'latex' / 'codeblocks.latex').read_text()
        definition = latex[latex.index('\\newcommand{\\breakablecode}'):]
        self.assertIn('\\csname f@size\\endcsname', definition.split('\n\n')[0])


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

    def test_font_size_is_11pt_unless_set(self):
        template = str(PIPELINE / 'latex' / 'template.latex')
        self.assertIn('\\documentclass[11pt]{article}', pandoc('Body.\n', '--template', template, '-M', 'title=T'))
        self.assertIn('\\documentclass[10pt]{article}',
                      pandoc('Body.\n', '--template', template, '-M', 'title=T', '-V', 'fontsize=10pt'))


class Chain(unittest.TestCase):
    """The PDF build runs the new filters, in the order they need."""

    def test_filter_order(self):
        script = (PIPELINE / 'scripts' / 'create_pdf.sh').read_text()
        pdf = next(line for line in script.splitlines() if 'pandoc_cmd="pandoc' in line and 'template' in line)
        order = [pdf.index(name) for name in
                 ['table-widths.lua', 'inline-code-breaks.lua', 'table-scale.lua', 'pandoc-mermaid.py',
                  'pandoc-minted.py']]
        self.assertEqual(order, sorted(order))


if __name__ == '__main__':
    unittest.main()
