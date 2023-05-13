local Config = require 'tabline_framework.config'
local functions = require 'tabline_framework.functions'
local Collector = require'tabline_framework.collector'
local hi = require 'tabline_framework.highlights'
local get_icon = require 'nvim-web-devicons'.get_icon

local Item = require'tabline_framework.item'
local Label = require'tabline_framework.label'

---@class T
---@field parts TablineFramework.Collector
local Tabline = {}
Tabline.__index = Tabline

local CurrentTab
---@alias TablineFramework.ActualBuf2 {item_list:{[number]:TablineFramework.item, buf_info:TablineFramework.buf_info}, default_callback?:string}?

function Tabline:use_tabline_colors()
  Item.fg = Config.hl.fg
  Item.bg = Config.hl.bg
  Item.gui = Config.hl.gui
end

function Tabline:use_tabline_sel_colors()
  Item.fg = Config.hl_sel.fg
  Item.bg = Config.hl_sel.bg
  Item.gui = Config.hl_sel.gui
end

function Tabline:use_tabline_fill_colors()
  Item.fg = Config.hl_fill.fg
  Item.bg = Config.hl_fill.bg
  Item.gui = Config.hl_fill.gui
end

---@param str string|number
---@param arg? TablineFramework.Item.arg
---@param collector TablineFramework.Collector
local function add(str, args, collector)
  local item = Item(str, args)
  collector:add(item)
end

---@param buf_list? number[]
---@param callback fun(info:TablineFramework.buf_info)
function Tabline:make_bufs(callback, buf_list)
  buf_list = buf_list or vim.api.nvim_list_bufs()
  ---@alias TablineFramework.buf_tab {[number]:TablineFramework.Item, buf_info:TablineFramework.buf_info}
  local label_list = self.parts:add(Collector())
  ---@param label TablineFramework.Label
  ---@return function
  local function new_add()
    local label = Label()
    label_list:add(label)
    return function (str, args)
      label:add_item (Item(str, args))
    end
  end
  local old_add = self.render_method.add

  local bufs_whiteList = {}
  for _, buf in ipairs(buf_list) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, 'buflisted') then
      table.insert(bufs_whiteList, buf)
    end
  end

  for i, buf in ipairs(bufs_whiteList) do
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
    local buf_info = {
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
    callback(buf_info)
    ActualBuf.item_list.buf_info = buf_info
    table.insert(label_list, ActualBuf.item_list)
    ActualBuf = nil
  end
  self:ajust_bufline(label_list)
  self:use_tabline_fill_colors()
  self:add('')
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
   local render_method = {
    icon = icon,
    icon_color = icon_color,
    ---@param opts TablineFramework.hl
    set_colors = function(opts)
      Item.fg = opts.fg or Item.fg
      Item.bg = opts.bg or Item.bg
      Item.gui = opts.gui or Item.gui
    end,
    ---@param arg_fg string
    set_fg = function(arg_fg) Item.fg = arg_fg or Item.fg end,
    ---@param arg_bg string
    set_bg = function(arg_bg) Item.bg = arg_bg or Item.bg end,
    ---@param arg_gui table<string, boolean>
    set_gui = function(arg_gui) Item.gui = arg_gui or Item.gui end,
    ---@param str string|number
    ---@param args? TablineFramework.Item.arg
    add = function(str, args) self:add(str, args, self.parts) end,
    add_spacer = function() self:add('%=', nil, self.parts) end,
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
  self.render_method = render_method
end

function Tabline:run(render_func)
  local o = setmetatable({
    parts = Collector()
  }, Tabline)
  return o:render(render_func)
end
