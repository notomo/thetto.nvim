local M = {}

M.default_config = {
  kind = {},
  kind_actions = {},

  source = {},
  source_actions = {},

  store = {},

  filters = nil,
  sorters = nil,
  global_opts = {},
}

M.config = vim.deepcopy(M.default_config)

function M.set(config)
  M.config = vim.tbl_deep_extend("force", M.config, config)
end

return M
