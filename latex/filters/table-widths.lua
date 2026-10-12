--[[
table-widths.lua - Give tables without column widths ones that wrap

A pipe table whose source lines are short gets no column widths from
pandoc, and LaTeX then sets each column as wide as its longest cell. Text
never wraps, and a table with long cells runs off the page.

When such a table's cells would not fit on one line of text, this gives
it widths in proportion to each column's longest cell (capped, so one long
cell does not take the whole page), but never narrower than the column's
longest word. Every column then wraps.

A table that fits stays as it is, compact and centred. "Fits" is pandoc's
own rule: its longest cells, side by side, take no more than 72
characters. Set the metadata field table-fit-chars to change that, lower
for a narrow page.

Tables that already have widths, from long source lines or a grid table,
are left as they are.

Run it before any filter that turns code or text into raw LaTeX, so the
cells can still be measured.
]]--

local CAP = 45 -- characters; a longer cell counts as this long
local fit_chars = 72

local function measure(rows, n, longest, natural)
  for _, row in ipairs(rows) do
    for i, cell in ipairs(row.cells) do
      if i <= n then
        local text = pandoc.utils.stringify(cell.contents)
        local word = 0
        for w in text:gmatch('[^%s/_]+') do
          word = math.max(word, utf8.len(w) or #w)
        end
        local length = utf8.len(text) or #text
        natural[i] = math.max(natural[i], length)
        longest[i] = math.max(longest[i], math.min(length, CAP), word + 2)
      end
    end
  end
end

local function Meta(meta)
  if meta['table-fit-chars'] then
    fit_chars = tonumber(pandoc.utils.stringify(meta['table-fit-chars'])) or fit_chars
  end
end

local function Table(tbl)
  local n = #tbl.colspecs
  for _, spec in ipairs(tbl.colspecs) do
    if spec[2] ~= nil then return nil end
  end
  local longest, natural = {}, {}
  for i = 1, n do longest[i] = 4; natural[i] = 0 end
  measure(tbl.head.rows, n, longest, natural)
  for _, body in ipairs(tbl.bodies) do measure(body.body, n, longest, natural) end
  local width = 0
  for i = 1, n do width = width + natural[i] + 2 end
  if width <= fit_chars then return nil end
  local total = 0
  for i = 1, n do total = total + longest[i] end
  for i = 1, n do tbl.colspecs[i] = {tbl.colspecs[i][1], longest[i] / total} end
  return tbl
end

return {{Meta = Meta}, {Table = Table}}
