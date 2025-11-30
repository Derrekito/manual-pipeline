-- notebook-toggle.lua
-- Pandoc Lua filter for notebook mode control via YAML front matter
-- Supports both global notebook: true/false toggle and per-block .suppress class
--
-- Usage in YAML front matter:
--   ---
--   notebook: true   # Keep all code blocks and outputs (notebook mode)
--   notebook: false  # Suppress all code blocks and outputs (document mode)
--   ---
--
-- Per-block suppression (works in notebook mode):
--   ```python {.suppress}
--   # This code block will be suppressed even in notebook mode
--   ```
--
--   ::: {.suppress .output}
--   This output will be suppressed
--   :::

-- Configuration
local suppress_in_latex_only = true  -- Set to false to suppress in all formats

-- Helper function to check if we should apply suppression
local function should_suppress()
  if suppress_in_latex_only then
    return FORMAT:match('latex') ~= nil
  end
  return true
end

-- Helper function to check if element has .suppress class
local function has_suppress_class(el)
  if el.classes then
    return el.classes:includes('suppress')
  end
  return false
end

-- Function to suppress a block (returns empty)
local function suppress_block(el)
  return {}
end

-- Per-block filter for .suppress class (used in notebook mode)
local function Block(el)
  if has_suppress_class(el) and should_suppress() then
    return {}
  end
  return el
end

-- Document-level filter for notebook toggle
function Pandoc(doc)
  local meta = doc.meta
  local is_notebook = meta.notebook

  -- Debug: print notebook mode status (visible in verbose output)
  if PANDOC_STATE and PANDOC_STATE.trace then
    if is_notebook == false then
      io.stderr:write("[notebook-toggle] Document mode: suppressing all code/outputs\n")
    elseif is_notebook == true then
      io.stderr:write("[notebook-toggle] Notebook mode: keeping code/outputs (respecting .suppress)\n")
    else
      io.stderr:write("[notebook-toggle] No notebook key found: defaulting to notebook mode\n")
    end
  end

  -- If notebook is explicitly false AND we're targeting LaTeX, suppress everything
  if is_notebook == false and should_suppress() then
    return doc:walk({
      CodeBlock = suppress_block,
      Div = suppress_block  -- Handles wrapped outputs
    })
  end

  -- Otherwise (notebook mode or no key), apply per-block .suppress only
  return doc:walk({
    CodeBlock = Block,
    Div = Block
  })
end

-- Return the filter
return {
  { Pandoc = Pandoc }
}
