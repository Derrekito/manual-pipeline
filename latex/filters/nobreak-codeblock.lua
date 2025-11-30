-- nobreak-codeblock.lua
-- Marks code blocks with .nobreak class for non-breaking tcolorbox
-- Usage: ```{.nobreak} or ```{.text .nobreak}

function CodeBlock(el)
  if el.classes:includes("nobreak") then
    -- Remove nobreak from classes
    local new_classes = {}
    for _, c in ipairs(el.classes) do
      if c ~= "nobreak" then
        table.insert(new_classes, c)
      end
    end
    el.classes = new_classes

    -- If no language specified, use text
    if #el.classes == 0 then
      el.classes = {"text"}
    end

    -- Add nobreak as an attribute so pandoc-minted.py can see it
    el.attributes["nobreak"] = "true"
  end
  return el
end
