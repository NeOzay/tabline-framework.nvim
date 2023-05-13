---@class TablineFramework.Label
---@operator call TablineFramework.Label
---@field [number] TablineFramework.Item
---@overload fun():TablineFramework.Label
local Label = {}
Label.__index = Label

---@param item TablineFramework.Item
function Label:add_item(item)
  table.insert(self, item)
end

function Label:__call(buf_nr)
  local current_buf = vim.api.nvim_get_current_buf()
  local current = vim.api.nvim_get_current_buf() == buf

  local default_callback = functions.register(function()
    vim.api.nvim_set_current_buf(buf)
  end)

  if current then
    self:use_tabline_sel_colors()
  else
    self:use_tabline_colors()
  end

  local buf_name = vim.api.nvim_buf_get_name(buf)
  local filename = vim.fn.fnamemodify(buf_name, ":t")
  local modified = vim.api.nvim_buf_get_option(buf, 'modified')

  ---@class TablineFramework.buf_info
  local label = {
    before_current = bufs_whiteList[i + 1] and bufs_whiteList[i + 1] == current_buf,
    after_current = bufs_whiteList[i - 1] and bufs_whiteList[i - 1] == current_buf,
    first = i == 1,
    last = i == #bufs_whiteList,
    index = i,
    current = current,
    buf = buf,
    buf_nr = buf,
    buf_name = buf_name,
    filename = #filename > 0 and filename or nil,
    modified = modified,
  }
  return setmetatable({}, Label)
end

function Label:finalise()
  local str = {}
  for index, item in ipairs(self) do
    table.insert(str, item:finalise())
  end
  return table.concat(str)
end

return Label
