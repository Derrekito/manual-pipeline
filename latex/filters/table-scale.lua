--[[
table-scale.lua - Shrink a table marked scale-to-fit to the width of the line

For LaTeX output, a table table-widths.lua marked is first set as a
tabular in a box that is never shown, to measure its natural width. If
that is wider than the line, its font and the space between its columns
are scaled by the line's width over the table's, and it is measured again
at the new size, three times in all, so it fits. It stays a longtable, so
it still breaks across pages.

A wrapped table that table-widths.lua marked scale-by, because its longest
words do not fit side by side, is set with its font and column gap scaled
by that factor.

Text in the table should be sized relative to the font around it, as
inline-code-breaks.lua sizes code, or it does not shrink with the rest.

Run it after every filter that changes what is inside table cells.
]]--

-- Defined once, by the first table: a box to measure in, and the command
-- that scales the font and column gap when the box is wider than the line.
local SETUP = [[
\ifdefined\tablefitbox\else
  \newsavebox\tablefitbox
  \newcommand\tablescaleby[1]{%
    \fontsize{\fpeval{#1 * \csname f@size\endcsname}}%
             {\fpeval{1.2 * #1 * \csname f@size\endcsname}}\selectfont
    \setlength\tabcolsep{#1\tabcolsep}}
  \newcommand\tablefitscale{%
    \ifdim\wd\tablefitbox>\linewidth
      \tablescaleby{\fpeval{\linewidth / \wd\tablefitbox}}%
    \fi}
\fi
]]

local PASSES = 3

-- The text of a brace group starting at position i, and the position after it.
local function group(s, i)
  local depth = 0
  for j = i, #s do
    local c = s:sub(j, j)
    if c == '{' then
      depth = depth + 1
    elseif c == '}' then
      depth = depth - 1
      if depth == 0 then return s:sub(i + 1, j - 1), j + 1 end
    end
  end
end

-- The longtable pandoc wrote, as a tabular with the same columns and rows:
-- header first, then the rows, then the closing rule. No caption.
local function tabular(latex)
  local start = latex:find('\\begin{longtable}[]', 1, true)
  local finish = latex:find('\\end{longtable}', 1, true)
  if not start or not finish then return nil end
  local spec, after = group(latex, start + #'\\begin{longtable}[]')
  local inner = latex:sub(after, finish - 1)
  local head_start = 1
  local cap = inner:find('\\caption', 1, true)
  if cap then
    local _, past = group(inner, cap + #'\\caption')
    head_start = inner:find('\\tabularnewline', past, true) + #'\\tabularnewline'
  end
  local first = inner:find('\\endfirsthead', 1, true)
  local endhead = inner:find('\\endhead', 1, true)
  local lastfoot = inner:find('\\endlastfoot', 1, true)
  if not endhead or not lastfoot then return nil end
  local head = inner:sub(head_start, (first or endhead) - 1)
  local foot = inner:sub(endhead + #'\\endhead', lastfoot - 1)
  local body = inner:sub(lastfoot + #'\\endlastfoot')
  -- A blank line would end a paragraph inside the tabular.
  local rows = (head .. body .. foot):gsub('\n%s*\n', '\n')
  return '\\begin{tabular}{' .. spec .. '}' .. rows .. '\\end{tabular}'
end

function Table(tbl)
  if not FORMAT:match('latex') then return nil end
  local by = tonumber(tbl.attr.attributes['scale-by'])
  if by then
    tbl.attr.attributes['scale-by'] = nil
    return pandoc.RawBlock('latex', SETUP .. '\\begingroup\n\\tablescaleby{' .. by .. '}\n' ..
      pandoc.write(pandoc.Pandoc({tbl}), 'latex') .. '\n\\endgroup')
  end
  if tbl.attr.attributes['scale-to-fit'] ~= 'true' then
    return nil
  end
  tbl.attr.attributes['scale-to-fit'] = nil
  local latex = pandoc.write(pandoc.Pandoc({tbl}), 'latex')
  local measure = tabular(latex)
  if not measure then return tbl end
  -- Measured again at each new size: a font with optical sizes is drawn
  -- wider when small, so one ratio can fall short.
  local pass = '\\begin{lrbox}{\\tablefitbox}' .. measure .. '\\end{lrbox}\n\\tablefitscale\n'
  return pandoc.RawBlock('latex', SETUP .. '\\begingroup\n' .. pass:rep(PASSES) .. latex .. '\n\\endgroup')
end
