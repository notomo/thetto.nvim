local M = {}

local _group_name_format = "thetto.completion.buffer_%s"

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
    return require("thetto.lib.cursor").word(window_id)
  end

  local source = require("thetto.util.source").merge(sources, {
    get_cursor_word = get_cursor_word,
    can_resume = false,
  })
  local thetto = require("thetto")
  local consumer = require("thetto.handler.consumer.complete")

  local on_discard = function() end
  local debounced = require("thetto.vendor.misclib.debounce").wrap(
    100,
    vim.schedule_wrap(function()
      thetto.start(source, {
        consumer_factory = function(consumer_ctx, _, _, callbacks)
          on_discard()
          on_discard = callbacks.on_discard

          return consumer.new(consumer_ctx.source_ctx.cursor_word, {
            priorities = priorities,
            source_to_label = source_to_label,
          })
        end,
      })
    end)
  )

  local bufnr = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup(_group_name_format:format(bufnr), {})
  vim.api.nvim_create_autocmd({
    "TextChangedI",
    "TextChangedP",
  }, {
    buffer = bufnr,
    group = group,
    callback = function()
      debounced()
    end,
  })
  vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    buffer = 0,
    group = group,
    callback = function()
      on_discard()
    end,
  })
end

function M.disable()
  local bufnr = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup(_group_name_format:format(bufnr), {})
  vim.api.nvim_clear_autocmds({
    buffer = bufnr,
    group = group,
  })
end

return M
