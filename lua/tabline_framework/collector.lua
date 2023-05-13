
---@class TablineFramework.Collector
---@operator call:TablineFramework.Collector
---@field [number] TablineFramework.item
local Collector = {}
Collector.__index = Collector
Collector.last_index = 0
---@generic K
---@param item K
---@return K
function Collector:add(item)
  table.insert(self, item)
  return item
end

function Collector:remove(item)
  for index, value in ipairs(self) do
    if item == value then
      table.remove(self, index)
    end
  end
end

Collector.__call = function()
  return setmetatable({ pos = {} }, Collector)
end

return setmetatable({}, Collector)
