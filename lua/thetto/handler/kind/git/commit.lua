local M = {}

local start = function(bufnr, item)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "diff"

  local cmd = { "git", "show", "--date=iso", item.commit_hash }
  return require("thetto.util.job").promise(cmd, {
    on_exit = function(job_self)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      local lines = job_self:get_output()
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end,
  })
end

local open = function(items, f)
  local promises = {}
  for _, item in ipairs(items) do
    local bufnr = vim.api.nvim_create_buf(false, true)
    local promise = start(bufnr, item)
    table.insert(promises, promise)
    f(bufnr)
  end
  return require("thetto.vendor.promise").all(promises)
end

function M.action_open(items)
  return open(items, function(bufnr)
    vim.cmd.buffer({ count = bufnr })
  end)
end

function M.action_vsplit_open(items)
  return open(items, function(bufnr)
    vim.cmd.vsplit()
    vim.cmd.buffer({ count = bufnr })
  end)
end

function M.action_tab_open(items)
  return open(items, function(bufnr)
    vim.cmd.tabedit()
    vim.cmd.buffer({ count = bufnr })
  end)
end

function M.action_preview(items, _, ctx)
  local item = items[1]
  if not item then
    return nil
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  local promise = start(bufnr, item)
  ctx.ui:open_preview(item, { raw_bufnr = bufnr })
  return promise
end

M.default_action = "open"

return M
