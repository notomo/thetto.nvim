local M = {}

--- @async
function M.action_open(items)
  return require("thetto.handler.kind.git._util").open(items, function(bufnr)
    vim.cmd.buffer(bufnr)
  end)
end

--- @async
function M.action_vsplit_open(items)
  return require("thetto.handler.kind.git._util").open(items, function(bufnr)
    vim.cmd.vsplit()
    vim.cmd.buffer(bufnr)
  end)
end

--- @async
function M.action_tab_open(items)
  return require("thetto.handler.kind.git._util").open(items, function(bufnr)
    require("thetto.lib.buffer").open_scratch_tab()
    vim.cmd.buffer(bufnr)
  end)
end

function M.get_preview(item)
  local util = require("thetto.handler.kind.git._util")
  return util.preview_diff(item, util.render_path_diff)
end

return require("thetto.core.kind").extend(M, "git/commit")
