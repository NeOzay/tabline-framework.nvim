---@class TablineFramework.Collector
---@operator call:TablineFramework.Collector
---@field [number] TablineFramework.item
local Collector = {}
Collector.__index = Collector

function Collector:add(item)
  table.insert(self, item)
end

function Collector:remove(item)
  for index, value in ipairs(self) do
    if item == value then
      table.remove(self, index)
    end
  end
end

Collector.__call = function()
  return setmetatable({}, Collector)
end

return setmetatable({}, Collector)
