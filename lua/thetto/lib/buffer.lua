local M = {}

function M.scratch(modify)
  modify = modify or function() end
  local bufnr = vim.api.nvim_create_buf(false, true)
  modify(bufnr)
  vim.bo[bufnr].bufhidden = "wipe"
  return bufnr
end

function M.open_scratch_tab()
  vim.cmd.tabedit()
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
end

function M.delete_by_name(name)
  local bufnr = vim.fn.bufnr(("^%s$"):format(name))
  if bufnr == -1 then
    return
  end
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

function M.in_tabpage(tabpage_index)
  local ids = vim.api.nvim_tabpage_list_wins(tabpage_index)
  local i = 1
  return function()
    while true do
      local id = ids[i]
      if id == nil then
        return
      end
      i = i + 1
      local bufnr = vim.fn.winbufnr(id)
      if vim.api.nvim_buf_is_valid(bufnr) then
        return bufnr, id
      end
    end
  end
end

function M.tab_drop(bufnr)
  for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
    for _, winnr in ipairs(vim.api.nvim_tabpage_list_wins(tabnr)) do
      if vim.api.nvim_win_get_buf(winnr) == bufnr then
        vim.api.nvim_set_current_tabpage(tabnr)
        vim.api.nvim_set_current_win(winnr)
        return
      end
    end
  end
  vim.cmd.tabnew()
  vim.api.nvim_win_set_buf(0, bufnr)
end

return M
