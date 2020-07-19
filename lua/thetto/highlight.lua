local M = {}

M.kind = function(bufnr, items, kind_name, highlight_group_name)
  local ns = vim.api.nvim_create_namespace("thetto-list-hihglight")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for i, item in ipairs(items) do
    if item.kind_name ~= kind_name then
      goto continue
    end
    vim.api.nvim_buf_add_highlight(bufnr, ns, highlight_group_name, i - 1, 0, -1)
    ::continue::
  end
end

return M
