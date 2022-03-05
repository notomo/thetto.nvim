local targets = require("thetto.core.target")

local M = {}

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
  cwd = ".",
  target = nil,
  target_patterns = {},
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
  local config = require("thetto.core.custom").config
  local source_config = config.source[source_name] or {}

  local opts = vim.tbl_extend("force", default, config.global_opts, source_config.global_opts or {}, raw_opts)
  opts.colors = source_config.colors or {}

  local filters = opts.filters
  opts.filters = function(source_filters)
    return filters or source_config.filters or source_filters or config.filters
  end

  local sorters = opts.sorters
  opts.sorters = function(source_sorters)
    return sorters or source_config.sorters or source_sorters or config.sorters
  end

  local source_opts = vim.tbl_extend("force", source_config.opts or {}, raw_source_opts)

  local cwd = vim.fn.expand(opts.cwd)
  if cwd == "." then
    cwd = vim.fn.fnamemodify(".", ":p")
  end
  if cwd ~= "/" and vim.endswith(cwd, "/") then
    cwd = cwd:sub(1, #cwd - 1)
  end

  if opts.target ~= nil then
    local target_cwd, err = targets.get(opts.target, opts.target_patterns)
    if err then
      return nil, nil, err
    end
    cwd = target_cwd
  end
  opts.cwd = cwd

  if type(opts.pattern) == "function" then
    opts.pattern = opts.pattern()
  end

  if not opts.range then
    opts.range = require("thetto.lib.mode").visual_range()
  end

  return opts, source_opts, nil
end

return M
