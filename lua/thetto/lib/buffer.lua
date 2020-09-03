local M = {}

M.scratch = function(modify)
  local bufnr = vim.api.nvim_create_buf(false, true)
  modify(bufnr)
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  return bufnr
end

M.in_tabpage = function(tabpage_index)
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
        return bufnr
      end
    end
  end
end

return M
