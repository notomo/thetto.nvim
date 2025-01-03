local M = {}

function M.by_name(source_name, fields, raw_opts)
  return require("thetto.core.source").by_name(source_name, fields, raw_opts)
end

function M.start_by_name(source_name, fields, opts)
  local source = require("thetto.core.source").by_name(source_name, fields)
  return require("thetto").start(source, opts)
end

local default_go_to_opts = {
  filter = function(_)
    return true
  end,
  fields = {
    can_resume = false,
  },
}

function M.go_to_next(source_name, raw_opts)
  local opts = vim.tbl_deep_extend("force", default_go_to_opts, raw_opts or {})

  local current_row = vim.fn.line(".")
  local path = vim.api.nvim_buf_get_name(0)
  vim.cmd.normal({ args = { "m'" }, bang = true })
  require("thetto.util.source").start_by_name(source_name, opts.fields, {
    consumer_factory = require("thetto.util.consumer").immediate({ action_name = "open" }),
    item_cursor_factory = require("thetto.util.item_cursor").search(function(item)
      return opts.filter(item) and item.path == path and item.row > current_row
    end),
  })
end

function M.go_to_previous(source_name, raw_opts)
  local opts = vim.tbl_deep_extend("force", default_go_to_opts, raw_opts or {})

  local current_row = vim.fn.line(".")
  local path = vim.api.nvim_buf_get_name(0)
  vim.cmd.normal({ args = { "m'" }, bang = true })
  require("thetto.util.source").start_by_name(source_name, opts.fields, {
    consumer_factory = require("thetto.util.consumer").immediate({ action_name = "open" }),
    item_cursor_factory = require("thetto.util.item_cursor").search(function(item)
      return opts.filter(item) and item.path == path and item.row < current_row
    end),
    pipeline_stages_factory = require("thetto.util.pipeline").merge({
      require("thetto.util.pipeline").apply_source(),
      require("thetto.util.pipeline").append({
        require("thetto.util.sorter").field_by_name("row", true),
      }),
    }),
  })
end

function M.filter(f)
  return function(items)
    return vim.iter(items):filter(f):totable()
  end
end

function M.merge(sources, fields)
  local SourceContext = require("thetto.core.source_context")
  local SourceSubscriber = require("thetto.core.source_subscriber")
  local Observable = require("thetto.vendor.misclib.observable")
  local source = {
    name = vim
      .iter(sources)
      :map(function(source)
        return source.name
      end)
      :join(","),

    collect = function(source_ctx)
      local count = #sources
      return function(observer)
        local completed = {}
        local cancels = vim
          .iter(sources)
          :enumerate()
          :map(function(i, source)
            local subscriber = SourceSubscriber.new(source, SourceContext.from(source, source_ctx))
            local observable = Observable.new(subscriber)
            local subscription = observable:subscribe({
              next = function(items)
                for _, item in ipairs(items) do
                  item.kind_name = item.kind_name or source.kind_name
                  item.source_name = item.source_name or source.name
                end
                observer:next(items)
              end,
              complete = function()
                completed[i] = true
                if vim.tbl_count(completed) == count then
                  observer:complete()
                end
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
  }
  return vim.tbl_deep_extend("force", source, fields or {})
end

return M
