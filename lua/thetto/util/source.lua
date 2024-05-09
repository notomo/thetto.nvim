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

return M
