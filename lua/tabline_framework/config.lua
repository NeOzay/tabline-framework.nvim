---@alias TablineFramework.hl { fg:string, bg:string, gui:table<string, true> }

---@class TablineFramework.Config
---@field render fun(t:TablineFramework.renderTable)
---@field hl TablineFramework.hl
---@field hl_sel TablineFramework.hl
---@field hl_fill TablineFramework.hl
---@field buflist_size number
---@field max number
---@field min number

---@type TablineFramework.Config
local Config = {data = {}}

---@param t TablineFramework.Config
---@param tbl? TablineFramework.Config
Config.new = function(t, tbl) rawset(t, 'data', tbl) end

---@param t TablineFramework.Config
---@param tbl TablineFramework.Config
Config.merge = function(t, tbl)
  for k, v in pairs(tbl) do
    rawget(t, 'data')[k] = v
  end
end

local functions = {
  new = true,
  merge = true
}

return setmetatable(Config, {
  __index = function(t, k)
    if functions[k] then
      return rawget(t, k)
    else
      return rawget(t, 'data')[k]
    end
  end,
  __newindex = function(t, k, v) rawget(t, 'data')[k] = v end,
})
