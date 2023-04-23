local print_warn = require 'tabline_framework.helpers'.print_warn
local Config = require 'tabline_framework.config'
local hi = require 'tabline_framework.highlights'
local functions = require 'tabline_framework.functions'
local Collector = require 'tabline_framework.collector'
local get_icon = require 'nvim-web-devicons'.get_icon

---@class TablineFramework.Tabline
---@field collector TablineFramework.Collector
local Tabline = {}
Tabline.__index = Tabline

---@alias TablineFramework.item {[1]:any, fg?:string, bg:string, gui:table<string, boolean>, closure?:fun(item:TablineFramework.item)}

local CurrentTab
---@type {item_list:{[number]:TablineFramework.item, buf_info:TablineFramework.buf_info}, default_callback?:string}?
local ActualBuf = { default_callback = nil, item_list = {} }
local function reset_actualBuf()
  ActualBuf = { default_callback = nil, item_list = {} }
end

function Tabline:use_tabline_colors()
  self.fg = Config.hl.fg
  self.bg = Config.hl.bg
  self.gui = Config.hl.gui
end

function Tabline:use_tabline_sel_colors()
  self.fg = Config.hl_sel.fg
  self.bg = Config.hl_sel.bg
  self.gui = Config.hl_sel.gui
end

function Tabline:use_tabline_fill_colors()
  self.fg = Config.hl_fill.fg
  self.bg = Config.hl_fill.bg
  self.gui = Config.hl_fill.gui
end

---@param callback fun(info:TablineFramework.tab_info)
---@param list any
function Tabline:make_tabs(callback, list)
  local tabs = list or vim.api.nvim_list_tabpages()
  for i, v in ipairs(tabs) do
    local current_tab = vim.api.nvim_get_current_tabpage()
    local current = current_tab == v

    if current then
      self:use_tabline_sel_colors()
    else
      self:use_tabline_colors()
    end

    local win = vim.api.nvim_tabpage_get_win(v)
    local buf = vim.api.nvim_win_get_buf(win)
    local buf_name = vim.api.nvim_buf_get_name(buf)
    local filename = vim.fn.fnamemodify(buf_name, ":t")
    local modified = vim.api.nvim_buf_get_option(buf, 'modified') ---@type boolean

    self:add('%' .. i .. 'T')

    CurrentTab = i
    ---@class TablineFramework.tab_info
    local tab_info = {
      before_current = tabs[i + 1] and tabs[i + 1] == current_tab,
      after_current  = tabs[i - 1] and tabs[i - 1] == current_tab,
      first          = i == 1,
      last           = i == #tabs,
      index          = i,
      tab            = v,
      current        = current,
      win            = win,
      buf            = buf,
      buf_nr         = buf,
      buf_name       = buf_name,
      filename       = #filename > 0 and filename or nil,
      modified       = modified,
    }
    callback(tab_info)
    CurrentTab = nil
  end
  self:add('%T')

  self:use_tabline_fill_colors()
  self:add('')
end

---@param buf_list number[]
---@param callback fun(info:TablineFramework.buf_info)
function Tabline:__make_bufs(buf_list, callback)
  local bufs = {}
  _G.tabBuf_list = {} ---@type TablineFramework.item[][]

  for _, buf in ipairs(buf_list) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, 'buflisted') then
      table.insert(bufs, buf)
    end
  end
  for i, buf in ipairs(bufs) do
    reset_actualBuf()
    ---@cast ActualBuf -?
    local current_buf = vim.api.nvim_get_current_buf()
    local current = vim.api.nvim_get_current_buf() == buf

    local default_callback = functions.register(function()
      vim.api.nvim_set_current_buf(buf)
    end)
    ActualBuf.closure = function(_item)
      _item[1] = '%@' .. default_callback .. '@' .. _item[1] .. '%X'
    end

    if current then
      self:use_tabline_sel_colors()
    else
      self:use_tabline_colors()
    end

    local buf_name = vim.api.nvim_buf_get_name(buf)
    local filename = vim.fn.fnamemodify(buf_name, ":t")
    local modified = vim.api.nvim_buf_get_option(buf, 'modified')

    ---@class TablineFramework.buf_info
    local buf_info = {
      before_current = bufs[i + 1] and bufs[i + 1] == current_buf,
      after_current = bufs[i - 1] and bufs[i - 1] == current_buf,
      first = i == 1,
      last = i == #bufs,
      index = i,
      current = current,
      buf = buf,
      buf_nr = buf,
      buf_name = buf_name,
      filename = #filename > 0 and filename or nil,
      modified = modified,
    }
    callback(buf_info)
    ActualBuf.item_list.buf_info = buf_info
    table.insert(tabBuf_list, ActualBuf.item_list)
  end
  ActualBuf = nil
  self:use_tabline_fill_colors()
  self:add('')
end

function Tabline:make_bufs(callback, list)
  return self:__make_bufs(list or vim.api.nvim_list_bufs(), callback)
end

function Tabline:make_tab_bufs(callback)
  local bufs = {}
  local wins = vim.api.nvim_tabpage_list_wins(0)

  for _, win in ipairs(wins) do
    table.insert(bufs, vim.api.nvim_win_get_buf(win))
  end

  return self:__make_bufs(bufs, callback)
end

---@param item TablineFramework.item|number|string
---@param closure? fun(item:TablineFramework.item)
function Tabline:add(item, closure)
  if type(item) == 'string' then
    item = { item }
  elseif type(item) == 'number' then
    item = { string(item) }
  elseif type(item) == 'table' then
    if not item[1] then return end
  else
    return
  end
  if ActualBuf and not closure then
    closure = ActualBuf.closure
  end
  if ActualBuf and ActualBuf.item_list then
    table.insert(ActualBuf.item_list, item)
  end

  item.fg = item.fg or self.fg
  item.bg = item.bg or self.bg
  item.gui = item.gui or self.gui
  item.closure = closure

  self.collector:add(item)
end

function Tabline:close_tab_btn(item)
  if not CurrentTab then
    print_warn 'TablineFramework: close_tab_btn function used outside the tab'
    return
  end

  self:add(item, function(tbl)
    tbl[1] = '%' .. CurrentTab .. 'X' .. tbl[1] .. '%X'
  end)
end

---@param item TablineFramework.item|number|string
---@param callback any
function Tabline:add_btn(item, callback)
  if not callback then
    print_warn 'TablineFramework: callback function not provided'
    return
  end

  self:add(item, function(_item)
    local name = functions.register(
    ---@param minwid number
    ---@param clicks number
    ---@param mouse_btn "r"|"l"
    ---@param modifiers any
      function(minwid, clicks, mouse_btn, modifiers)
        ---@class TablineFramework.ButtonCallback
        local button = {
          minwid = minwid,
          clicks = clicks,
          mouse_btn = mouse_btn,
          modifiers = modifiers
        }
        callback(button)
      end)
    _item[1] = '%@' .. name .. '@' .. _item[1] .. '%X'
  end)
end

---@param name string? file name
---@return string? icon
local function icon(name)
  if not name then return end
  local i = get_icon(name, nil, { default = true })
  return i
end

local function icon_color(name)
  if not name then return end

  local _, hl = get_icon(name, nil, { default = true })
  return hi.get_hl(hl).fg
end

---@param render_func fun(t:TablineFramework.renderTable)
---@return string
function Tabline:render(render_func)
  local content = {}

  functions.clear()
  self:use_tabline_fill_colors()
  ---@class TablineFramework.renderTable
  local struc = {
    icon = icon,
    icon_color = icon_color,
    ---@param opts TablineFramework.hl
    set_colors = function(opts)
      self.fg = opts.fg or self.fg
      self.bg = opts.bg or self.bg
      self.gui = opts.gui or self.gui
    end,
    ---@param arg_fg string
    set_fg = function(arg_fg) self.fg = arg_fg or self.fg end,
    ---@param arg_bg string
    set_bg = function(arg_bg) self.bg = arg_bg or self.bg end,
    ---@param arg_gui table<string, boolean>
    set_gui = function(arg_gui) self.gui = arg_gui or self.gui end,
    ---@param arg TablineFramework.item|number|string
    add = function(arg) self:add(arg) end,
    add_spacer = function() self:add('%=') end,
    ---@param callback fun(info:TablineFramework.tab_info)
    ---@param list? number[]
    make_tabs = function(callback, list) self:make_tabs(callback, list) end,
    ---@param callback fun(info:TablineFramework.buf_info)
    ---@param list? number[]
    make_bufs = function(callback, list) self:make_bufs(callback, list) end,
    close_tab_btn = function(arg) self:close_tab_btn(arg) end,
    ---@param arg TablineFramework.item|number|string
    ---@param callback fun(b:TablineFramework.ButtonCallback)
    add_btn = function(arg, callback) self:add_btn(arg, callback) end,
    -- make_tab_bufs = function(callback) self:make_tab_bufs(callback) end,
  }

  render_func(struc)

  for _, item in ipairs(self.collector) do ---@cast item TablineFramework.item
    local text = item.closure and item.closure(item) or item[1]
    table.insert(content, ('%%#%s#%s'):format(hi.set_hl(item.fg, item.bg, item.gui), text))
  end

  return table.concat(content)
end

Tabline.run = function(callback)
  local new_obj = setmetatable({
    collector = Collector()
  }, Tabline)
  return new_obj:render(callback)
end


return Tabline
