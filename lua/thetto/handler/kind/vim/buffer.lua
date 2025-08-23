local M = {}

function M.action_open(items)
  for _, item in ipairs(items) do
    vim.cmd.buffer(item.bufnr)
  end
end

function M.action_tab_open(items)
  for _, item in ipairs(items) do
    require("thetto.lib.buffer").open_scratch_tab()
    vim.cmd.buffer(item.bufnr)
  end
end

function M.action_vsplit_open(items)
  for _, item in ipairs(items) do
    vim.cmd.vsplit()
    vim.cmd.buffer(item.bufnr)
  end
end

function M.action_tab_drop(items)
  for _, item in ipairs(items) do
    local path = vim.api.nvim_buf_get_name(item.bufnr)
    local tab = vim.fn.tabpagenr()
    if path ~= "" then
      vim.cmd.drop({ mods = { tab = tab }, args = { path }, magic = { file = false } })
    end
  end
end

function M.action_reload(items)
  local bufnrs = vim
    .iter(items)
    :map(function(item)
      local bufnr = item.bufnr
      if vim.bo[bufnr].buftype ~= "" then
        return nil
      end
      return bufnr
    end)
    :totable()
  for _, bufnr in ipairs(bufnrs) do
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd.edit({ bang = true })
    end)
  end
end

function M.get_preview(item)
  if not vim.api.nvim_buf_is_loaded(item.bufnr) then
    return
  end
  return nil, { bufnr = item.bufnr }
end

M.default_action = "open"

return M
