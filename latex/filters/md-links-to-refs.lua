-- md-links-to-refs.lua
-- Converts markdown file links to internal LaTeX references for PDF output
-- Leaves links unchanged for other output formats (HTML, markdown, etc.)

-- Helper: extract anchor from URL (e.g., "file.md#section-name" -> "section-name")
local function get_anchor(url)
  return url:match("#(.+)$")
end

-- Helper: check if URL points to a markdown file
local function is_md_link(url)
  -- Match .md files, with or without anchors
  return url:match("%.md$") or url:match("%.md#")
end

-- Helper: convert anchor text to valid LaTeX label
-- Pandoc auto-generates labels from headings using this scheme
local function normalize_label(anchor)
  if not anchor then return nil end
  -- Pandoc's default: lowercase, spaces to hyphens, remove special chars
  return anchor:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
end

function Link(el)
  -- Only transform for LaTeX output
  if not FORMAT:match("latex") then
    return el
  end

  local url = el.target

  -- Only process markdown file links
  if not is_md_link(url) then
    return el
  end

  local anchor = get_anchor(url)

  if anchor then
    -- Link with anchor: [text](file.md#section) -> \hyperref[section]{text}
    local label = normalize_label(anchor)
    local link_text = pandoc.utils.stringify(el.content)
    return pandoc.RawInline('latex',
      string.format('\\hyperref[%s]{%s}', label, link_text))
  else
    -- Link without anchor: [text](file.md) -> just the text (or could link to file label)
    -- For now, just return the link text since we can't know where to link
    return el.content
  end
end
