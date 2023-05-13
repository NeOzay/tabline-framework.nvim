local functions = {}
local functions_index = 0

---@type table<function, string>
local registered = {}

local function clear()

  for k, _ in pairs(registered) do registered[k] = nil end
  for k, _ in pairs(functions) do functions[k] = nil end
  functions_index = 0
end

---@param callback function
---@return string
local function register(callback)
  local name = registered[callback]

  if not name then
    ---@param minwid number
    ---@param clicks number
    ---@param mouse_btn "r"|"l"
    ---@param modifiers any
      local function handle(minwid, clicks, mouse_btn, modifiers)
        ---@class TablineFramework.ButtonCallback
        local button = {
          minwid = minwid,
          clicks = clicks,
          mouse_btn = mouse_btn,
          modifiers = modifiers
        }
        callback(button)
      end
    functions_index = functions_index + 1
    name = 'fn_nr_' .. functions_index
    functions[name] = handle
    registered[callback] = name
  end

  return [[v:lua.require'tabline_framework.functions'.functions.]] .. name
end

return {
  clear = clear,
  register = register,
  functions = functions,
  functions_index = functions_index
}
