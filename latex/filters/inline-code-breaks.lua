--[[
inline-code-breaks.lua - Let long inline code wrap at the end of a line

\mintinline cannot break, so a long path or name in backticks runs into
the margin, worst in table cells. For LaTeX output this sets inline code
that has no language in the code font at the code size, the same look
\mintinline gives it, with break points after / _ . - = and ,

Inline code with a language class, `x`{.python}, is left for
pandoc-minted.py to highlight. Run this before pandoc-minted.py.
]]--

local SPECIAL = {
  ['\\'] = '\\textbackslash{}', ['{'] = '\\{', ['}'] = '\\}', ['$'] = '\\$', ['&'] = '\\&',
  ['#'] = '\\#', ['^'] = '\\textasciicircum{}', ['_'] = '\\_', ['%'] = '\\%',
  ['~'] = '\\textasciitilde{}',
}
local BREAK = {['/'] = true, ['_'] = true, ['.'] = true, ['-'] = true, ['='] = true, [','] = true}

function Code(code)
  if not FORMAT:match('latex') or #code.classes > 0 then
    return nil
  end
  local out = {}
  for _, c in utf8.codes(code.text) do
    local ch = utf8.char(c)
    table.insert(out, SPECIAL[ch] or ch)
    if BREAK[ch] then table.insert(out, '\\allowbreak{}') end
  end
  return pandoc.RawInline('latex', '{\\codefont\\footnotesize ' .. table.concat(out) .. '}')
end
