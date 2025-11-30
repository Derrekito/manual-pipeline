--[[
include-files.lua - Include external markdown files
Usage in markdown:
  {{include path/to/file.md}}
  or
  !include path/to/file.md

Paths are relative to the input document being processed.
]]--

-- Store the directory of the input file
local input_dir = nil

function get_input_dir(meta)
  -- Try to get the input file from PANDOC_STATE
  if PANDOC_STATE and PANDOC_STATE.input_files and #PANDOC_STATE.input_files > 0 then
    local input_file = PANDOC_STATE.input_files[1]
    input_dir = pandoc.path.directory(input_file)
  end
  return meta
end

function strip_yaml_frontmatter(content)
  -- Remove YAML front matter if present
  -- YAML front matter starts with --- at the beginning and ends with ---
  -- Split into lines and check if first line is ---
  local lines = {}
  local in_frontmatter = false
  local frontmatter_ended = false
  local line_num = 0

  for line in content:gmatch("([^\n]*)\n?") do
    line_num = line_num + 1

    if line_num == 1 and line:match("^%s*%-%-%-+%s*$") then
      -- First line is ---, start of YAML frontmatter
      in_frontmatter = true
    elseif in_frontmatter and line:match("^%s*%-%-%-+%s*$") then
      -- Found closing ---, end of frontmatter
      in_frontmatter = false
      frontmatter_ended = true
    elseif not in_frontmatter and frontmatter_ended then
      -- After frontmatter, keep the line
      table.insert(lines, line)
    elseif not in_frontmatter and not frontmatter_ended then
      -- No frontmatter found, keep all lines
      table.insert(lines, line)
    end
    -- Skip lines that are inside frontmatter
  end

  return table.concat(lines, "\n")
end

function read_include_file(path)
  -- Construct full path relative to input directory
  local full_path = path
  if input_dir and input_dir ~= "" then
    full_path = pandoc.path.join({input_dir, path})
  end

  -- Try to read the file
  local file, err = io.open(full_path, "r")
  if not file then
    io.stderr:write(string.format("[include-files] Warning: Could not open file '%s': %s\n", full_path, err or "unknown error"))
    return nil
  end

  local content = file:read("*all")
  file:close()

  -- Strip YAML front matter from included files
  content = strip_yaml_frontmatter(content)

  io.stderr:write(string.format("[include-files] Successfully included: %s\n", full_path))
  return content
end

-- Shift all heading levels by n (positive = demote, e.g., # becomes ##)
function shift_headings(blocks, shift)
  if shift == 0 then return blocks end
  local shifted = {}
  for _, block in ipairs(blocks) do
    if block.t == "Header" then
      local new_level = block.level + shift
      if new_level > 6 then new_level = 6 end
      if new_level < 1 then new_level = 1 end
      table.insert(shifted, pandoc.Header(new_level, block.content, block.attr))
    else
      table.insert(shifted, block)
    end
  end
  return shifted
end

-- Prefix all heading IDs with a given prefix to avoid duplicates
function prefix_heading_ids(blocks, prefix)
  if not prefix or prefix == "" then return blocks end
  local prefixed = {}
  for _, block in ipairs(blocks) do
    if block.t == "Header" then
      local attr = block.attr
      local id = attr.identifier
      -- Only prefix if ID doesn't already have a custom prefix (contains hyphen in first segment)
      if id and id ~= "" and not id:match("^[a-z]+-[a-z]+%-") then
        attr.identifier = prefix .. "-" .. id
      end
      table.insert(prefixed, pandoc.Header(block.level, block.content, attr))
    else
      table.insert(prefixed, block)
    end
  end
  return prefixed
end

-- Extract prefix from file path (e.g., "services/dut-ingest.md" -> "dut-ingest")
function get_prefix_from_path(path)
  -- Get basename without extension
  local basename = path:match("([^/]+)%.md$") or path:match("([^/]+)$")
  if basename then
    -- Remove .md extension if still present
    basename = basename:gsub("%.md$", "")
    return basename
  end
  return nil
end

-- Strip the first heading if it's level 1
function strip_first_h1(blocks)
  local result = {}
  local stripped = false
  for _, block in ipairs(blocks) do
    if not stripped and block.t == "Header" and block.level == 1 then
      stripped = true  -- Skip this heading
    else
      table.insert(result, block)
    end
  end
  return result
end

-- Parse include directive and return path, shift_level, strip_h1
function parse_include_directive(text)
  -- Patterns:
  --   !include path              -> include as-is
  --   !include-shift path        -> shift headings by 1
  --   !include-shift:N path      -> shift headings by N
  --   !include-headless path     -> strip first h1
  --   {{include path}}           -> include as-is

  local path, shift, strip_h1 = nil, 0, false

  -- Check for {{include path}}
  path = text:match("^{{include%s+(.+)}}$")
  if path then return path, 0, false end

  -- Check for !include-headless path (strips first h1 AND shifts remaining by 1)
  path = text:match("^!include%-headless%s+(.+)$")
  if path then return path, 1, true end

  -- Check for !include-shift:N path
  local n, p = text:match("^!include%-shift:(%d+)%s+(.+)$")
  if n and p then return p, tonumber(n), false end

  -- Check for !include-shift path (default shift=1)
  path = text:match("^!include%-shift%s+(.+)$")
  if path then return path, 1, false end

  -- Check for plain !include path
  path = text:match("^!include%s+(.+)$")
  if path then return path, 0, false end

  return nil, 0, false
end

function process_include(text)
  local path, shift, strip_h1 = parse_include_directive(text)

  if path then
    local content = read_include_file(path)
    if content then
      -- Parse the markdown content WITHOUT YAML metadata parsing
      local doc = pandoc.read(content, "markdown-yaml_metadata_block")
      local blocks = doc.blocks

      -- Apply transformations
      if strip_h1 then
        blocks = strip_first_h1(blocks)
      end
      if shift > 0 then
        blocks = shift_headings(blocks, shift)
      end

      -- Prefix heading IDs based on source filename to avoid duplicates
      local prefix = get_prefix_from_path(path)
      if prefix then
        blocks = prefix_heading_ids(blocks, prefix)
      end

      return blocks
    end
  end

  return nil
end

function Para(el)
  local text = pandoc.utils.stringify(el)
  local blocks = process_include(text)
  if blocks then return blocks end
  return el
end

function RawBlock(el)
  if el.format == "markdown" then
    local blocks = process_include(el.text)
    if blocks then return blocks end
  end
  return el
end

-- Return the filters in the correct order
return {
  { Meta = get_input_dir },  -- First, capture the input directory
  { Para = Para, RawBlock = RawBlock }  -- Then process includes
}
