--[[
title-logo.lua - Put logos from the front matter on the title page

  logo: example-logo.pdf            # one logo
  logo: [ours.pdf, partner.pdf]     # several, spread across the page
  logo-width: 0.3\textwidth         # optional, 0.25\textwidth unless given

No logo key, or logo: false, means no logo. A bare file name is found in
the project's assets/logos, then the pipeline's; a path is taken from the
manual directory. The file name is passed to \includegraphics as written,
so underscores and the like survive. Sets logo-block for titlepage.latex.
]]--

local DEFAULT_WIDTH = '0.25\\textwidth'

local function latex(value)
  if type(value) == 'string' then return value end
  local inlines = pandoc.Inlines(value)
  local out = {}
  for _, el in ipairs(inlines) do
    table.insert(out, el.t == 'RawInline' and el.text or pandoc.utils.stringify(el))
  end
  return table.concat(out)
end

function Meta(meta)
  local logo = meta.logo
  if not logo or logo == false or not FORMAT:match('latex') then
    return nil
  end
  local files = {}
  if pandoc.utils.type(logo) == 'List' then
    for _, item in ipairs(logo) do table.insert(files, pandoc.utils.stringify(item)) end
  else
    table.insert(files, pandoc.utils.stringify(logo))
  end
  local width = meta['logo-width'] and latex(meta['logo-width']) or DEFAULT_WIDTH
  local lines = {'\\vfill', '\\hfill'}
  for _, file in ipairs(files) do
    if file ~= '' then
      table.insert(lines, '\\includegraphics[width=' .. width .. ']{' .. file .. '}')
      table.insert(lines, '\\hfill')
    end
  end
  if #lines == 2 then return nil end
  table.insert(lines, '\\null\\par')
  meta['logo-block'] = pandoc.RawInline('latex', table.concat(lines, '\n'))
  return meta
end
