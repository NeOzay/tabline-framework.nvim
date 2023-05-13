local functions = require'tabline_framework.functions'
local hi = require'tabline_framework.highlights'
local config = require('tabline_framework.config')

---@class TablineFramework.Item
---@field private _closure? function
---@overload fun(s:string|number, args?:TablineFramework.Item.arg):TablineFramework.Item
local Item = {}
Item.__index = Item

Item.fg = config.hl.fg
Item.bg = config.hl.bg
Item.gui = config.hl.gui
---@alias TablineFramework.Item.arg {fg?:string, bg?:string, gui?:table<string, true>, callback?:function, min?:number, max?:number}

local closure = function (self)
  local name = functions.register(self.callback)
  local s = '%@' .. name .. '@' .. self[1] .. '%X'
  return s
end

---@param s number|string
---@param arg? TablineFramework.Item.arg
---@return TablineFramework.Item
Item.__call = function(self, s, arg)
  arg = arg or {}
  ---@class TablineFramework.Item
  local item = {tostring(s)}
  item.fg = arg.fg or Item.fg
  item.bg = arg.bg or Item.bg
  item.gui = arg.gui or Item.gui
  item.min = arg.min
  item.max = arg.max
  item.callback = arg.callback
  return item
end

function Item:finalise()
  local text = self[1]
  if self.callback then
    text = closure(self)
  end
  return ('%%#%s#%s'):format(hi.set_hl(self.fg, self.bg, self.gui), text)
end

return Item

