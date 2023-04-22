local colors = {}
local color_index = 0

local function clear()
  colors = {}
  color_index = 0
end

---@param fg string
---@param bg string
---@param gui? table<string, boolean>
local function set_hl(fg, bg, gui)
  if not fg and not bg and not gui then return end
  local function tostringGui(t)
    local sort = {}
    for key, value in pairs(t or {}) do
      table.insert(sort, key)
    end
    table.sort(sort)
    return table.concat(sort,",")
  end
  local key = fg:sub(2) .. '_' .. bg:sub(2) .. (gui and tostringGui(gui) or "")

  if colors[key] then return colors[key] end

  color_index = color_index + 1
  local group = 'TablineFramework_' .. color_index
  colors[key] = group

  -- local cmd = ('highlight %s guifg=%s guibg=%s gui=%s'):format(
  --   group,
  --   fg or 'NONE',
  --   bg or 'NONE',
  --   gui or 'NONE'
  -- )
  local val = vim.tbl_extend("keep", {
    fg = fg,
    bg = bg,
  }, gui or {})
  vim.api.nvim_set_hl(0, group, val)
  --vim.api.nvim_command(cmd)
  return group
end

local function get_hl(color)
  local c = vim.api.nvim_get_hl(0, { name = color })
  return {
    fg = c.fg and string.format('#%06x', c.fg) or 'NONE',
    bg = c.bg and string.format('#%06x', c.bg) or 'NONE'
  }
end

local function tabline()
  return get_hl('TabLine')
end

local function tabline_sel()
  return get_hl('TabLineSel')
end

local function tabline_fill()
  return get_hl('TabLineFill')
end

return {
  clear = clear,
  set_hl = set_hl,
  get_hl = get_hl,
  tabline = tabline,
  tabline_sel = tabline_sel,
  tabline_fill = tabline_fill,
}
