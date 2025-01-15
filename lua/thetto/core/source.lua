local M = {}

--- @class ThettoSource
--- @field name string
--- @field kind_name string
--- @field collect fun(source_ctx:ThettoSourceContext):(table[]|fun(observer:Observer))
--- @field opts table?
--- @field consumer_opts table?
--- @field cwd (string|fun():string)?
--- @field can_resume boolean?
--- @field modify_pipeline fun(stages:table[],opts:table)?
--- @field get_pattern (fun():string)?
--- @field key (fun(key_ctx:{source:ThettoSource}):string)?
--- @field highlight (fun(decorator:table,items:table[],first_line:integer,source_ctx:ThettoSourceContext))?
--- @field actions table?

local _registered = {}

local default_opts = {
  use_registered = true,
}
function M.by_name(source_name, fields, raw_opts)
  local opts = vim.tbl_deep_extend("force", default_opts, raw_opts or {})

  local registered = _registered[source_name]
  if opts.use_registered and registered then
    if type(registered) == "function" then
      registered = registered()
    end
    return vim.tbl_deep_extend("force", vim.deepcopy(registered), fields or {})
  end

  local origin = require("thetto.vendor.misclib.module").find("thetto.handler.source." .. source_name)
  if not origin then
    error("not found source: " .. source_name)
  end

  local source = vim.tbl_deep_extend("force", vim.deepcopy(origin), fields or {})
  source.name = source_name
  source.can_resume = source.can_resume == nil and true or source.can_resume
  return source
end

function M.register(source_name, source)
  _registered[source_name] = source
end

function M.setup(sources)
  _registered = vim.tbl_extend("force", _registered, sources or {})
end

function M.registered_names()
  return vim.iter(vim.tbl_keys(_registered)):totable()
end

return M
