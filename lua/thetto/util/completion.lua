local M = {}

local _group = "thetto_completion"

function M.enable(sources)
  local priorities = {}
  vim.iter(sources):enumerate():each(function(i, source)
    priorities[source.name] = math.pow(100, #sources - i)
  end)

  local debounced = require("thetto.vendor.misclib.debounce").wrap(
    100,
    vim.schedule_wrap(function()
      require("thetto").start(require("thetto.util.source").merge(sources), {
        consumer_factory = function()
          return require("thetto.handler.consumer.complete").new({
            priorities = priorities,
          })
        end,
      })
    end)
  )

  local group = vim.api.nvim_create_augroup(_group, {})
  vim.api.nvim_create_autocmd({ "InsertEnter", "TextChangedI" }, {
    buffer = 0,
    group = group,
    callback = function()
      debounced()
    end,
  })
end

function M.disable()
  vim.api.nvim_clear_autocmds({
    buffer = 0,
    group = _group,
  })
end

return M
