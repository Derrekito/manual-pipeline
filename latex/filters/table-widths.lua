--[[
table-widths.lua - Decide how a table without column widths fits the line

A pipe table whose source lines are short gets no column widths from
pandoc, and LaTeX then sets each column as wide as its longest cell. Text
never wraps, and a wide table runs off the page.

For LaTeX, every such table is marked scale-to-fit, for table-scale.lua,
which measures it and shrinks it to the line only if it is wider.

When the shrinking would go below table-min-scale (default 0.6), the
table is given wrapping columns instead. Each column gets at least the
width of its longest word, and the rest of the line goes to the columns
by how much more text they hold (a cell counts at most 45 characters, so
one long cell does not take the whole page). If even the longest words do
not fit side by side, the table is also marked scale-by, to shrink its
font by that much. The estimates count characters against
table-fit-chars, the characters of text a line holds (default 72); lower
it for a narrow page. Both are metadata fields.

Tables that already have widths, from long source lines or a grid table,
are left as they are.

Run it before any filter that turns code or text into raw LaTeX, so the
cells can still be measured, and table-scale.lua after those.
]]--

local CAP = 45 -- characters; a longer cell counts as this long
local settings = {['table-fit-chars'] = 72, ['table-min-scale'] = 0.6}

local function measure(rows, n, longest, natural, word)
  for _, row in ipairs(rows) do
    for i, cell in ipairs(row.cells) do
      if i <= n then
        local text = pandoc.utils.stringify(cell.contents)
        for w in text:gmatch('[^%s/_]+') do
          word[i] = math.max(word[i], utf8.len(w) or #w)
        end
        local length = utf8.len(text) or #text
        natural[i] = math.max(natural[i], length)
        longest[i] = math.max(longest[i], math.min(length, CAP))
      end
    end
  end
end

local function Meta(meta)
  for name, _ in pairs(settings) do
    if meta[name] then
      settings[name] = tonumber(pandoc.utils.stringify(meta[name])) or settings[name]
    end
  end
end

local function Table(tbl)
  local n = #tbl.colspecs
  for _, spec in ipairs(tbl.colspecs) do
    if spec[2] ~= nil then return nil end
  end
  local longest, natural, word = {}, {}, {}
  for i = 1, n do longest[i] = 4; natural[i] = 0; word[i] = 0 end
  measure(tbl.head.rows, n, longest, natural, word)
  for _, body in ipairs(tbl.bodies) do measure(body.body, n, longest, natural, word) end
  local width = 0
  for i = 1, n do width = width + natural[i] + 2 end
  local line = settings['table-fit-chars']
  if line / width >= settings['table-min-scale'] then
    if FORMAT:match('latex') then
      tbl.attr.attributes['scale-to-fit'] = 'true'
    end
    return tbl
  end
  -- Wrap: each column gets at least its longest word, as a share of the
  -- line, and the rest of the line goes by how much more each column holds.
  local floor, floors, extra = {}, 0, 0
  for i = 1, n do
    floor[i] = (word[i] + 2) / line
    floors = floors + floor[i]
    extra = extra + math.max(longest[i] + 2 - (word[i] + 2), 0)
  end
  for i = 1, n do
    local share = floor[i]
    if floors < 1 then
      local more = math.max(longest[i] - word[i], 0)
      share = floor[i] + (1 - floors) * (extra > 0 and more / extra or 1 / n)
    else
      share = floor[i] / floors
    end
    tbl.colspecs[i] = {tbl.colspecs[i][1], share}
  end
  -- Words that do not fit side by side even so: shrink the table's font by
  -- the overshoot as well.
  if floors > 1 and FORMAT:match('latex') then
    tbl.attr.attributes['scale-by'] = string.format('%.3f', 1 / floors)
  end
  return tbl
end

return {{Meta = Meta}, {Table = Table}}
