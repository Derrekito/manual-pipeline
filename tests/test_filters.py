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


@unittest.skipUnless(shutil.which('pandoc'), 'needs pandoc')
class Callouts(unittest.TestCase):
    """GitHub alerts become callout boxes; other block quotes stay quotes."""

    lua = ['--lua-filter', str(FILTERS / 'callouts.lua')]

    def test_alert_becomes_a_callout_titled_with_its_type(self):
        latex = pandoc('> [!NOTE]\n> Example note\n', *self.lua)
        self.assertIn('\\begin{callout}{note}{Note}', latex)
        self.assertIn('Example note', latex)
        self.assertIn('\\end{callout}', latex)
        self.assertNotIn('quote', latex)

    def test_each_github_type_has_its_style(self):
        for kind in ['note', 'tip', 'important', 'warning', 'caution']:
            self.assertIn('\\begin{callout}{%s}' % kind, pandoc(f'> [!{kind.upper()}]\n> x\n', *self.lua))

    def test_other_names_take_the_nearest_style_and_keep_their_word(self):
        self.assertIn('\\begin{callout}{note}{Notes}', pandoc('> [!NOTES]\n> x\n', *self.lua))
        self.assertIn('\\begin{callout}{caution}{Danger}', pandoc('> [!DANGER]\n> x\n', *self.lua))
        self.assertIn('\\begin{callout}{note}{Example}', pandoc('> [!EXAMPLE]\n> x\n', *self.lua))

    def test_text_after_the_marker_is_the_title(self):
        latex = pandoc('> [!WARNING]- Back *up* first\n> body\n>\n> more\n', *self.lua)
        self.assertIn('\\begin{callout}{warning}{Back \\emph{up} first}', latex)
        self.assertLess(latex.index('body'), latex.index('more'))

    def test_gfm_alert_is_boxed_the_same(self):
        latex = pandoc('> [!TIP]\n> x\n', *self.lua, reader='gfm')
        self.assertIn('\\begin{callout}{tip}{Tip}', latex)

    def test_plain_quote_is_left_alone(self):
        self.assertIn('\\begin{quote}', pandoc('> just a [quote]\n', *self.lua))

    def test_other_formats_get_a_div_with_a_bold_title(self):
        html = pandoc('> [!NOTE]\n> x\n', *self.lua, to='html')
        self.assertIn('<div class="callout callout-note">', html)
        self.assertIn('<strong>Note</strong>', html)


@unittest.skipUnless(shutil.which('pandoc'), 'needs pandoc')
class TitleLogo(unittest.TestCase):
    """Logos named in the front matter go on the title page; none by default."""

    def title_page(self, *args):
        latex = pandoc('Body.\n', '--template', str(PIPELINE / 'latex' / 'template.latex'),
                       '--lua-filter', str(FILTERS / 'title-logo.lua'), '-M', 'title=T', *args)
        return latex[latex.index('\\begin{titlepage}'):latex.index('\\end{titlepage}')]

    def test_no_logo_unless_asked(self):
        self.assertNotIn('includegraphics', self.title_page())
        self.assertNotIn('includegraphics', self.title_page('-M', 'logo=false'))

    def test_logo_file_is_used_as_written(self):
        page = self.title_page('-M', 'logo=my_org-logo.pdf')
        self.assertIn('\\includegraphics[width=0.25\\textwidth]{my_org-logo.pdf}', page)

    def test_several_logos_and_a_width(self):
        page = pandoc('---\ntitle: T\nlogo: [a.pdf, b.pdf]\nlogo-width: 0.3\\textwidth\n---\nBody.\n',
                      '--template', str(PIPELINE / 'latex' / 'template.latex'),
                      '--lua-filter', str(FILTERS / 'title-logo.lua'))
        self.assertIn('\\includegraphics[width=0.3\\textwidth]{a.pdf}', page)
        self.assertIn('\\includegraphics[width=0.3\\textwidth]{b.pdf}', page)

    def test_example_logo_is_shipped(self):
        self.assertTrue((PIPELINE / 'assets' / 'logos' / 'example-logo.pdf').is_file())


@unittest.skipUnless(shutil.which('pandoc'), 'needs pandoc')
class PageSize(unittest.TestCase):
    """Letter with the pipeline's margins unless papersize or geometry say otherwise."""

    def geometry(self, *args):
        latex = pandoc('Body.\n', '--template', str(PIPELINE / 'latex' / 'template.latex'), *args)
        start = latex.index('\\usepackage[', latex.index('% Letter unless'))
        return ' '.join(latex[start:latex.index('{geometry}', start)].split())

    def test_letter_by_default(self):
        self.assertIn('[letterpaper, top=0.5in, bottom=1in, left=1in, right=1in, includeheadfoot]',
                      self.geometry())

    def test_papersize_sets_the_paper(self):
        self.assertIn('[a4paper, top=0.5in', self.geometry('-M', 'papersize=a4'))

    def test_paper_name_is_accepted_however_written(self):
        lua = ['--lua-filter', str(FILTERS / 'page-size.lua')]
        for name in ['a4', 'A4', 'a4paper', 'A4Paper']:
            self.assertIn('[a4paper, top=0.5in', self.geometry(*lua, '-M', f'papersize={name}'))

    def test_geometry_replaces_the_margins(self):
        g = self.geometry('-M', 'geometry=margin=2cm', '-M', 'papersize=a5')
        self.assertIn('[a5paper, margin=2cm, includeheadfoot]', g)


class Chain(unittest.TestCase):
    """The PDF build runs the new filters, in the order they need."""

    def test_filter_order(self):
        pdf = (PIPELINE / 'defaults' / 'pdf.yaml').read_text()
        order = [pdf.index(name) for name in
                 ['callouts.lua', 'table-widths.lua', 'inline-code-breaks.lua', 'table-scale.lua', 'pandoc-mermaid.py',
                  'pandoc-minted.py']]
        self.assertEqual(order, sorted(order))

    def test_defaults_reference_existing_files(self):
        for name in ['pdf.yaml', 'docx.yaml']:
            defaults = PIPELINE / 'defaults' / name
            paths = re.findall(r'^\s*(?:template:|-)\s+(\S+)\s*$', defaults.read_text(), re.MULTILINE)
            self.assertTrue(paths, name)
            for path in paths:
                with self.subTest(defaults=name, path=path):
                    self.assertTrue(path.startswith('${.}/'), path)
                    self.assertTrue((defaults.parent / path.removeprefix('${.}/')).is_file(), path)


if __name__ == '__main__':
    unittest.main()
