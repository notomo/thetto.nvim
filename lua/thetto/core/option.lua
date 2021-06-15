local custom = require("thetto/custom")
local inputs = require("thetto/core/input")
local targets = require("thetto/core/target")

local M = {}

local Options = {}
Options.__index = Options
M.Options = Options

local default = {
  insert = true,
  resume = false,
  ignorecase = false,
  smartcase = true,
  pattern = nil,
  pattern_type = nil,
  offset = 0,
  cwd = ".",
  target = nil,
  target_patterns = {},
  action = nil,
  display_limit = 100,
  debounce_ms = 50,
  filters = {},
  sorters = {},
  allow_empty = false,
  auto = nil,
  immediately = false,
  range = nil,
}

function Options.new(raw)
  local opts = vim.tbl_extend("force", default, custom.opts, raw)

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

  if opts.pattern_type ~= nil then
    local p, err = inputs.get(opts.pattern_type)
    if err ~= nil then
      return nil, err
    end
    opts.pattern = p
  end

  return setmetatable(opts, Options), nil
end

function Options.default_empty()
  local opts = {}
  for key, value in pairs(default) do
    if type(value) == "table" then
      opts[key] = value
    end
  end
  return opts
end

return M
