local targets = require("thetto.core.target")

local M = {}

local Options = {}
Options.__index = Options
M.Options = Options

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
  allow_empty = false,
  auto = nil,
  immediately = false,
  range = nil,
}

function Options.new(raw, source_name)
  local config = require("thetto.core.custom").config
  local source_config = config.source[source_name] or {}
  local opts = vim.tbl_extend("force", default, config.global_opts, source_config.global_opts or {}, raw)

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
      return nil, err
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

  return setmetatable(opts, Options), nil
end

return M
