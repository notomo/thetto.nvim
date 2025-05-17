local M = {}

local _group_name_format = "thetto.completion.buffer_%s"
local cache = {}
local clear_cache = function()
  for _, k in ipairs(vim.tbl_keys(cache)) do
    cache[k] = nil
  end
end

local default_opts = {
  kind_priorities = {},
}

function M.enable(sources, raw_opts)
  local opts = vim.tbl_extend("force", default_opts, raw_opts or {})

  local starter = M._starter(sources, false, opts)
  local debounced = require("thetto.vendor.misclib.debounce").wrap(100, vim.schedule_wrap(starter.start))
  local consumer = starter.consumer

  local bufnr = vim.api.nvim_get_current_buf()
  local changedtick = vim.b[bufnr].changedtick
  local group = vim.api.nvim_create_augroup(_group_name_format:format(bufnr), {})
  vim.api.nvim_create_autocmd({
    "TextChangedI",
    "TextChangedP",
  }, {
    buffer = bufnr,
    group = group,
    callback = function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      local new = vim.b[bufnr].changedtick
      if new == changedtick then
        return
      end
      changedtick = new

      consumer:cancel()
      debounced()
    end,
  })

  M._set_autocmd(sources, bufnr, group, starter.cancel)
end

function M.disable()
  local bufnr = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup(_group_name_format:format(bufnr), { clear = false })
  vim.api.nvim_clear_autocmds({
    buffer = bufnr,
    group = group,
  })
end

function M.trigger(sources, raw_opts)
  local opts = vim.tbl_extend("force", default_opts, raw_opts or {})

  local starter = M._starter(sources, true, opts)

  local bufnr = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup(_group_name_format:format(bufnr), { clear = false })
  M._set_autocmd(sources, bufnr, group, starter.cancel)

  clear_cache()

  return starter.start()
end

function M._starter(sources, is_manual, opts)
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
  }, cache, is_manual)
  local thetto = require("thetto")
  local consumer = require("thetto.handler.consumer.complete").new({
    priorities = priorities,
    kind_priorities = opts.kind_priorities,
    source_to_label = source_to_label,
  })

  local on_discard = function() end
  local starter = {
    consumer = consumer,
    cancel = function()
      on_discard()
      consumer:cancel()
    end,
    start = function()
      return thetto.start(source, {
        consumer_factory = function(consumer_ctx, _, _, callbacks)
          on_discard = callbacks.on_discard
          consumer:apply(consumer_ctx.source_ctx.cursor_word)
          return consumer
        end,
      })
    end,
  }
  return starter
end

function M._set_autocmd(sources, bufnr, group, cancel_collect)
  vim.api.nvim_create_autocmd({ "ModeChanged" }, {
    buffer = bufnr,
    group = group,
    callback = function()
      clear_cache()
    end,
  })

  local source_map = vim.iter(sources):fold({}, function(acc, s)
    acc[s.name] = s
    return acc
  end)

  M._set_resolver(source_map, bufnr, group)
  local cancel_set_completion_info = M._set_completion_info(source_map, bufnr, group)
  vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    buffer = bufnr,
    group = group,
    callback = function()
      cancel_collect()
      cancel_set_completion_info()
    end,
  })
end

function M._set_completion_info(source_map, bufnr, group)
  local cancel = function() end
  vim.api.nvim_create_autocmd({ "CompleteChanged" }, {
    buffer = bufnr,
    group = group,
    callback = function()
      cancel()

      local info = vim.fn.complete_info({ "selected", "completed" })
      local index = info.selected
      if index == -1 then
        return
      end

      local source_name = info.completed.user_data.source_name
      local source = source_map[source_name]
      if not source then
        return
      end

      if source.edit_on_completion then
        local client_id = info.completed.user_data.client_id
        local offset = info.completed.user_data.offset
        local original_item = info.completed.user_data.item
        source.edit_on_completion(bufnr, client_id, original_item, offset)
      end

      if not source.set_completion_info then
        return
      end
      cancel = source.set_completion_info(index)
    end,
  })

  return function()
    cancel()
  end
end

function M._set_resolver(source_map, bufnr, group)
  local cancel = function() end
  vim.api.nvim_create_autocmd({ "CompleteDone" }, {
    buffer = bufnr,
    group = group,
    callback = function()
      local completed_item = vim.v.completed_item
      if vim.tbl_isempty(completed_item) then
        return
      end
      cancel()

      if vim.tbl_get(vim.v.event, "reason") == "cancel" then
        return
      end

      local source_name = completed_item.user_data.source_name
      local source = source_map[source_name]
      if not source then
        return
      end

      if not source.resolve then
        return
      end
      local client_id = completed_item.user_data.client_id
      local offset = completed_item.user_data.offset
      cancel = source.resolve(completed_item.user_data.item, client_id, offset) or function() end
    end,
  })
end

return M
