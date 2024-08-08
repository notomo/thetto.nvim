local M = {}

local _group = "thetto_completion"

function M.enable(sources)
  local priorities = {}
  vim.iter(sources):enumerate():each(function(i, source)
    priorities[source.name] = math.pow(100, #sources - i)
  end)

  local source_to_label = {}
  vim.iter(sources):each(function(source)
    source_to_label[source.name] = source.kind_label
  end)

  local get_cursor_words = vim
    .iter(sources)
    :map(function(source)
      return source.get_cursor_word
    end)
    :totable()
  local get_cursor_word = function(window_id)
    for _, f in ipairs(get_cursor_words) do
      local cursor_word = f(window_id)
      if cursor_word then
        return cursor_word
      end
    end
  end

  local source = require("thetto.util.source").merge(sources, {
    can_resume = false,
  })
  local thetto = require("thetto")
  local consumer = require("thetto.handler.consumer.complete")

  local debounced = require("thetto.vendor.misclib.debounce").wrap(
    100,
    vim.schedule_wrap(function()
      thetto.start(source, {
        consumer_factory = function(consumer_ctx)
          local window_id = consumer_ctx.source_ctx.window_id
          local cursor_word = get_cursor_word(window_id)
          return consumer.new({
            priorities = priorities,
            cursor_word = cursor_word,
            source_to_label = source_to_label,
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
