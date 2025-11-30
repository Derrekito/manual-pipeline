#!/usr/bin/env python3
''' A pandoc filter that has the LaTeX writer use minted for typesetting code.

Usage:
    pandoc --filter ./minted.py -o myfile.tex myfile.md
'''

from string import Template
from pandocfilters import toJSONFilter, RawBlock, RawInline


def unpack_code(value, language):
    ''' Unpack the body and language of a pandoc code element. '''
    [[_, classes, attributes], contents] = value
    if len(classes) > 0:
        language = classes[0]
    # Check for nobreak attribute
    nobreak = False
    filtered_attrs = []
    for attr in attributes:
        if attr[0] == 'nobreak':
            nobreak = True
        else:
            filtered_attrs.append(attr)
    attributes = ', '.join('='.join(x) for x in filtered_attrs)
    return {'contents': contents, 'language': language, 'attributes': attributes, 'nobreak': nobreak}


def unpack_metadata(meta):
    ''' Unpack the metadata to get pandoc-minted settings. '''
    settings = meta.get('pandoc-minted', {})
    if settings.get('t', '') == 'MetaMap':
        settings = settings['c']
        language = settings.get('language', {})
        if language.get('t', '') == 'MetaInlines':
            language = language['c'][0]['c']
        else:
            language = None
        return {'language': language}
    return {'language': 'text'}


def minted(key, value, format, meta):
    ''' Use minted for code in LaTeX. '''
    if format != 'latex':
        return
    if key == 'CodeBlock':
        settings = unpack_metadata(meta)
        code = unpack_code(value, settings['language'])

        # Use non-breaking version for .nobreak diagrams, terminal style for everything else
        if code['nobreak']:
            template = Template(
                '\\begin{mymintednobreak}[$attributes]{$language}\n$contents\n\\end{mymintednobreak}'
            )
        else:
            template = Template(
                '\\begin{terminal}[$attributes]{$language}\n$contents\n\\end{terminal}'
            )
        Element = RawBlock
    elif key == 'Code':
        template = Template('\\mintinline[$attributes]{$language}{$contents}')
        Element = RawInline
        settings = unpack_metadata(meta)
        code = unpack_code(value, settings['language'])
    else:
        return
    if not code['contents'].strip():  # Skip empty code blocks
        return None
    return [Element(format, template.substitute(code))]


if __name__ == '__main__':
    toJSONFilter(minted)
