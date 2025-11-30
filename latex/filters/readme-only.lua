--[[
readme-only.lua - Strip readme-only sections from LaTeX output

Removes Div elements with class "readme-only" when generating LaTeX/PDF.
Content remains visible in markdown renderers (GitHub, etc.).

Usage in markdown:
  ::: {.readme-only}
  Content here only appears in README, not in PDF
  :::
]]--

function Div(el)
  if el.classes:includes("readme-only") then
    if FORMAT:match("latex") then
      return {}
    end
  end
  return el
end
