---@class TablineFramework.Collector
---@operator call:TablineFramework.Collector
---@field [number] TablineFramework.item
---@field last_index number
---@field pos table<any, integer>
local Collector = {}
Collector.__index = Collector
Collector.last_index = 0
function Collector:add(item)
  self.last_index = self.last_index + 1
  self.pos[item] = self.last_index
  table.insert(self, item)
end

function Collector:remove(item)
  table.remove(self, self.pos[item])
end

Collector.__call = function()
  return setmetatable({ pos = {} }, Collector)
end

return setmetatable({}, Collector)
