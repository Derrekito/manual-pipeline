--[[
callouts.lua - GitHub alerts as boxed callouts

  > [!NOTE]
  > Useful information.

  > [!WARNING] Back up first
  > Text after the marker replaces the title.

The five GitHub types NOTE, TIP, IMPORTANT, WARNING and CAUTION each have
their own colour and icon (the callout environment in callouts.latex).
Common other names take the nearest style (NOTES and INFO as a note, HINT
as a tip, DANGER and ERROR as a caution); any other [!WORD] is boxed as a
note titled with that word. Obsidian's fold marks, [!NOTE]- and
[!NOTE]+, are dropped. Alerts read by pandoc's gfm reader, which arrive as
a Div with a title Div, are boxed the same way.

For LaTeX the title and body stay pandoc elements, so later filters still
see the code and tables inside. Other formats get a Div with a bold title.
]]--

local STYLE = {
  note = 'note', notes = 'note', info = 'note', abstract = 'note', summary = 'note',
  tip = 'tip', tips = 'tip', hint = 'tip', success = 'tip',
  important = 'important',
  warning = 'warning', warn = 'warning', attention = 'warning',
  caution = 'caution', danger = 'caution', error = 'caution', bug = 'caution',
}
local GITHUB = {note = true, tip = true, important = true, warning = true, caution = true}

local function title_case(word)
  return word:sub(1, 1):upper() .. word:sub(2):lower()
end

local function box(kind, title, body)
  local style = STYLE[kind:lower()] or 'note'
  if #title == 0 then title = pandoc.Inlines(title_case(kind)) end
  if FORMAT:match('latex') then
    local open = pandoc.Plain({pandoc.RawInline('latex', '\\begin{callout}{' .. style .. '}{')})
    open.content:extend(title)
    open.content:insert(pandoc.RawInline('latex', '}'))
    local blocks = pandoc.Blocks({open})
    blocks:extend(body)
    blocks:insert(pandoc.RawBlock('latex', '\\end{callout}'))
    return blocks
  end
  local blocks = pandoc.Blocks({pandoc.Para({pandoc.Strong(title)})})
  blocks:extend(body)
  return pandoc.Div(blocks, pandoc.Attr('', {'callout', 'callout-' .. style}))
end

local function trim(inlines)
  while #inlines > 0 and (inlines[1].t == 'Space' or inlines[1].t == 'SoftBreak') do inlines:remove(1) end
  while #inlines > 0 and (inlines[#inlines].t == 'Space' or inlines[#inlines].t == 'SoftBreak') do
    inlines:remove(#inlines)
  end
  return inlines
end

function BlockQuote(quote)
  local first = quote.content[1]
  if not first or (first.t ~= 'Para' and first.t ~= 'Plain') or #first.content == 0 then return nil end
  local marker = first.content[1]
  local kind = marker.t == 'Str' and marker.text:match('^%[!(%a+)%][-+]?$')
  if not kind then return nil end
  -- The title runs to the end of the marker's line; the rest is the first paragraph.
  local title, rest, in_title = pandoc.Inlines({}), pandoc.Inlines({}), true
  for i = 2, #first.content do
    local el = first.content[i]
    if in_title and (el.t == 'SoftBreak' or el.t == 'LineBreak') then
      in_title = false
    elseif in_title then
      title:insert(el)
    else
      rest:insert(el)
    end
  end
  local body = pandoc.Blocks({})
  if #trim(rest) > 0 then body:insert(pandoc[first.t](rest)) end
  for i = 2, #quote.content do body:insert(quote.content[i]) end
  return box(kind, trim(title), body)
end

function Div(div)
  local kind = div.classes[1]
  local head = div.content[1]
  if #div.classes ~= 1 or not GITHUB[kind] or not head or head.t ~= 'Div' or not head.classes:includes('title') then
    return nil
  end
  local title = pandoc.utils.blocks_to_inlines(head.content)
  if pandoc.utils.stringify(title) == title_case(kind) then title = pandoc.Inlines({}) end
  local body = pandoc.Blocks({})
  for i = 2, #div.content do body:insert(div.content[i]) end
  return box(kind, title, body)
end
