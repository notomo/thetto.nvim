local M = {}

function M.collect()
  local current = vim.lsp.log.get_level()
  return vim
    .iter({
      "TRACE",
      "DEBUG",
      "INFO",
      "WARN",
      "ERROR",
      "OFF",
    })
    :map(function(level_name)
      local level = vim.lsp.log[level_name]
      return {
        value = level_name,
        level = level,
        is_current = current == level,
      }
    end)
    :totable()
end

M.kind_name = "word"

M.actions = {
  action_set = function(items)
    local item = items[1]
    if not item then
      return
    end
    vim.lsp.log.set_level(item.level)
  end,
  default_action = "set",
}

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Type",
    filter = function(item)
      return item.is_current
    end,
  },
})

return M
