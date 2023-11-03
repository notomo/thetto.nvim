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

function M.resolve_alias(source_name, original_source_config)
  original_source_config = original_source_config or {}
  local source_config = M.user_default.source[source_name] or {}
  local alias_to = source_config.alias_to
  local extended_config = vim.tbl_deep_extend("force", source_config, original_source_config)
  if not alias_to then
    return source_name, extended_config
  end
  return M.resolve_alias(alias_to, extended_config)
end

function M._resolve_one_alias(source_name)
  local source_config = M.user_default.source[source_name] or {}
  local alias_to = source_config.alias_to
  if not alias_to then
    return source_name
  end
  return M._resolve_one_alias(alias_to)
end

function M.resolve_all_aliases()
  local resolved_source_map = {}
  for source_name in pairs(M.user_default.source) do
    local resolved_source_name = M._resolve_one_alias(source_name)
    if resolved_source_name ~= source_name then
      resolved_source_map[source_name] = resolved_source_name
    end
  end
  return resolved_source_map
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
  search_offset = nil,
  cwd = function()
    return "."
  end,
  action = nil,
  display_limit = 100,
  throttle_ms = 50,
  filters = nil,
  filter = function(_)
    return true
  end,
  sorters = nil,
  auto = "preview",
  immediately = false,
  range = nil,
  can_resume = true,
}

local function build_filters(filters, ...)
  if not filters and vim.tbl_count({ ... }) == 0 then
    return {}
  end
  if type(filters) == "function" then
    return filters(build_filters(...))
  end
  return filters or build_filters(...)
end

function Option.new(raw_opts, raw_source_opts, source_config)
  raw_opts = raw_opts or {}
  local opts = {}

  local filters = raw_opts.filters
  opts.filters = function(source_filters)
    return build_filters(filters, source_config.filters, source_filters, M.user_default.filters, { "substring" })
  end

  local sorters = raw_opts.sorters
  opts.sorters = function(source_sorters)
    return sorters or source_config.sorters or source_sorters or M.user_default.sorters
  end

  opts.behaviors = function(behaviors)
    behaviors = behaviors or {}

    local merged =
      vim.tbl_extend("force", default, M.user_default.global_opts, behaviors, source_config.global_opts or {}, raw_opts)

    local cwd = merged.cwd
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
    merged.cwd = cwd

    local pattern = merged.pattern
    if type(pattern) == "function" then
      merged.pattern = pattern()
    end

    if not merged.range then
      merged.range = require("thetto.vendor.misclib.visual_mode").row_range()
    end

    return merged
  end

  local source_opts = vim.tbl_extend("force", source_config.opts or {}, raw_source_opts)
  return opts, source_opts, nil
end

local ExecuteOption = {}
ExecuteOption.__index = ExecuteOption
M.ExecuteOption = ExecuteOption

function ExecuteOption.new(source_name, source_actions)
  source_actions = source_actions or {}

  local user_source_actions =
    vim.tbl_deep_extend("force", source_actions, M.user_default.source_actions[source_name] or {})
  user_source_actions.opts = user_source_actions.opts or {}
  user_source_actions.behaviors = user_source_actions.behaviors or {}

  local tbl = {
    kind_actions = M.user_default.kind_actions,
    source_actions = user_source_actions,
  }
  return setmetatable(tbl, ExecuteOption)
end

return M
