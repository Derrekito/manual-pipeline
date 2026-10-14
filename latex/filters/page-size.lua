--[[
page-size.lua - Accept the paper name however it is written

The template sets geometry's paper as $papersize$paper, pandoc's own
convention, so papersize: a4 gives a4paper. This lowercases the name and
drops a trailing "paper", so A4, a4paper and letterpaper work too.
]]--

function Meta(meta)
  if not meta.papersize then return nil end
  local name = pandoc.utils.stringify(meta.papersize):lower():gsub('%s', ''):gsub('paper$', '')
  meta.papersize = pandoc.MetaString(name)
  return meta
end
