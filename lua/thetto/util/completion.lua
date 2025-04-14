local M = {}

local _group_name_format = "thetto.completion.buffer_%s"
local cache = {}
local clear_cache = function()
  cache = {}
end

function M.enable(sources)
  local starter, consumer = M._starter(sources)
  local on_discard = function() end
  local on_consumer_factory = function(callbacks)
    on_discard = callbacks.on_discard
  end
  local debounced = require("thetto.vendor.misclib.debounce").wrap(
    100,
    vim.schedule_wrap(function()
      starter(on_consumer_factory)
    end)
  )

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

  vim.api.nvim_create_autocmd({ "ModeChanged" }, {
    buffer = bufnr,
    group = group,
    callback = function()
      clear_cache()
    end,
  })

  local cancel_resolve = M._set_resolver(sources, bufnr, group)
  local cancel_set_completion_info = M._set_completion_info(sources, bufnr, group)
  vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    buffer = bufnr,
    group = group,
    callback = function()
      on_discard()
      consumer:cancel()
      cancel_resolve()
      cancel_set_completion_info()
    end,
  })
end

function M.disable()
  local bufnr = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup(_group_name_format:format(bufnr), { clear = false })
  vim.api.nvim_clear_autocmds({
    buffer = bufnr,
    group = group,
  })
end

function M.trigger(sources)
  local starter, consumer = M._starter(sources, { is_manual = true })
  local on_discard = function() end
  local on_consumer_factory = function(callbacks)
    on_discard = callbacks.on_discard
  end

  clear_cache()
  starter(on_consumer_factory)

  local bufnr = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup(_group_name_format:format(bufnr), { clear = false })

  vim.api.nvim_create_autocmd({ "ModeChanged" }, {
    buffer = bufnr,
    group = group,
    callback = function()
      clear_cache()
    end,
  })

  local cancel_set_completion_info = M._set_completion_info(sources, bufnr, group)
  vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    buffer = bufnr,
    group = group,
    callback = function()
      on_discard()
      consumer:cancel()
      cancel_set_completion_info()
    end,
  })
end

function M._starter(sources, raw_consumer_opts)
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

  local SourceContext = require("thetto.core.source_context")
  local SourceSubscriber = require("thetto.core.source_subscriber")
  local Observable = require("thetto.vendor.misclib.observable")
  local name = function(i, source)
    return source.name or ("merged_source_" .. i)
  end

  local consumer_opts = vim.tbl_deep_extend("force", {
    priorities = priorities,
    source_to_label = source_to_label,
  }, raw_consumer_opts or {})

  local source = require("thetto.util.source").merge(sources, {
    get_cursor_word = get_cursor_word,
    can_resume = false,

    collect = function(source_ctx)
      local count = #sources
      return function(observer)
        local completed = {}
        local complete = function(i)
          completed[i] = true
          if vim.tbl_count(completed) == count then
            observer:complete()
          end
        end

        local cancels = vim
          .iter(sources)
          :enumerate()
          :map(function(i, source)
            local specific_source_ctx = SourceContext.from(source, source_ctx, consumer_opts.is_manual)
            if source.min_trigger_length and #specific_source_ctx.cursor_word.str < source.min_trigger_length then
              complete(i)
              return
            end

            local save_cache = source.should_collect
                and function(items)
                  cache[i] = cache[i] or {}
                  vim.list_extend(cache[i], items)
                end
              or function() end

            if cache[i] and source.should_collect and not source.should_collect(specific_source_ctx) then
              local items = cache[i]
              observer:next(items)
              complete(i)
              return
            end

            local subscriber = SourceSubscriber.new(source, specific_source_ctx)
            local observable = Observable.new(subscriber)
            local subscription = observable:subscribe({
              next = function(items)
                for _, item in ipairs(items) do
                  item.kind_name = item.kind_name or source.kind_name
                  item.source_name = item.source_name or name(i, source)
                end
                save_cache(items)
                observer:next(items)
              end,
              complete = function()
                complete(i)
              end,
              error = function(...)
                observer:error(...)
              end,
            })
            return function()
              subscription:unsubscribe()
            end
          end)
          :totable()
        return function()
          for _, cancel in ipairs(cancels) do
            cancel()
          end
        end
      end
    end,
  })
  local thetto = require("thetto")
  local consumer = require("thetto.handler.consumer.complete").new(consumer_opts)
  return function(on_consumer_factory)
    thetto.start(source, {
      consumer_factory = function(consumer_ctx, _, _, callbacks)
        on_consumer_factory(callbacks)
        consumer:apply(consumer_ctx.source_ctx.cursor_word)
        return consumer
      end,
    })
  end,
    consumer
end

function M._set_completion_info(sources, bufnr, group)
  local source_map = vim.iter(sources):fold({}, function(acc, s)
    acc[s.name] = s
    return acc
  end)

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

function M._set_resolver(sources, bufnr, group)
  local source_map = vim.iter(sources):fold({}, function(acc, s)
    acc[s.name] = s
    return acc
  end)

  local cancel = function() end
  vim.api.nvim_create_autocmd({ "CompleteDone" }, {
    buffer = bufnr,
    group = group,
    callback = function()
      cancel()

      local completed_item = vim.v.completed_item
      if vim.tbl_isempty(completed_item) then
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
      cancel = source.resolve(completed_item.user_data.item) or function() end
    end,
  })

  return function()
    cancel()
  end
end

return M
