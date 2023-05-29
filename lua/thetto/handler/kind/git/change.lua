local M = {}

function M.action_open(items)
  return require("thetto.handler.kind.git._util").open(items, function(bufnr)
    vim.cmd.buffer(bufnr)
  end)
end

function M.action_vsplit_open(items)
  return require("thetto.handler.kind.git._util").open(items, function(bufnr)
    vim.cmd.vsplit()
    vim.cmd.buffer(bufnr)
  end)
end

function M.action_tab_open(items)
  return require("thetto.handler.kind.git._util").open(items, function(bufnr)
    require("thetto.lib.buffer").open_scratch_tab()
    vim.cmd.buffer(bufnr)
  end)
end

return require("thetto.core.kind").extend(M, "git/commit")
