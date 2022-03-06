local M = {}

M.user_default = {
  kind_actions = {},

  source = {},
  source_actions = {},

  filters = nil,
  sorters = nil,
  global_opts = {},
}
function M.set_default(setting)
  vim.validate({ setting = { setting, "table" } })
  M.user_default = vim.tbl_deep_extend("force", M.user_default, setting)
end

local Option = {}
Option.__index = Option
M.Option = Option

local default = {
  insert = true,
  ignorecase = false,
  smartcase = true,
  input_lines = {},
  pattern = function()
    return nil
  end,
  offset = 0,
  cwd = function()
    return "."
  end,
  action = nil,
  display_limit = 100,
  debounce_ms = 50,
  filters = nil,
  sorters = nil,
  auto = nil,
  immediately = false,
  range = nil,
}

function Option.new(raw_opts, raw_source_opts, source_name)
  local source_config = M.user_default.source[source_name] or {}

  local opts = vim.tbl_extend("force", default, M.user_default.global_opts, source_config.global_opts or {}, raw_opts)
  opts.colors = source_config.colors or {}

  local filters = opts.filters
  opts.filters = function(source_filters)
    return filters or source_config.filters or source_filters or M.user_default.filters
  end

  local sorters = opts.sorters
  opts.sorters = function(source_sorters)
    return sorters or source_config.sorters or source_sorters or M.user_default.sorters
  end

  local cwd = opts.cwd
  if type(cwd) == "function" then
    cwd = cwd()
  end
  cwd = vim.fn.expand(cwd)
  if cwd == "." then
    cwd = vim.fn.fnamemodify(".", ":p")
  end
  if cwd ~= "/" and vim.endswith(cwd, "/") then
    cwd = cwd:sub(1, #cwd - 1)
  end
  opts.cwd = cwd

  if type(opts.pattern) == "function" then
    opts.pattern = opts.pattern()
  end

  if not opts.range then
    opts.range = require("thetto.lib.mode").visual_range()
  end

  local source_opts = vim.tbl_extend("force", source_config.opts or {}, raw_source_opts)
  return opts, source_opts, nil
end

local ExecuteOption = {}
ExecuteOption.__index = ExecuteOption
M.ExecuteOption = ExecuteOption

function ExecuteOption.new(source_name)
  local source_actions = M.user_default.source_actions[source_name] or {}
  source_actions.opts = source_actions.opts or {}
  source_actions.behaviors = source_actions.behaviors or {}

  local tbl = {
    kind_actions = M.user_default.kind_actions,
    source_actions = source_actions,
  }
  return setmetatable(tbl, ExecuteOption)
end

return M
