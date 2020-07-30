local M = {}

local ns_key = "thetto-list-highlight"
local selection_ns_key = "thetto-selection-highlight"
local sign_ns_key = "thetto-sign-highlight"

M.reset = function(bufnr)
  local ns = vim.api.nvim_create_namespace(ns_key)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  return ns
end

M.kind = function(bufnr, items, ns, kind_name, highlight_group)
  for i, item in ipairs(items) do
    if item.kind_name ~= kind_name then
      goto continue
    end
    vim.api.nvim_buf_add_highlight(bufnr, ns, highlight_group, i - 1, 0, -1)
    ::continue::
  end
end

M.color_labels = function(bufnr, items, colors, key)
  local ns = vim.api.nvim_create_namespace(sign_ns_key)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for i, item in ipairs(items) do
    for _, color in ipairs(colors) do
      if color.regex:match_str(item[key]) then
        vim.api.nvim_buf_set_virtual_text(bufnr, ns, i - 1, color.chunks, {})
        break
      end
    end
  end
end

M.update_selections = function(bufnr, items)
  local ns = vim.api.nvim_create_namespace(selection_ns_key)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for i, item in ipairs(items) do
    if item.selected then
      vim.api.nvim_buf_add_highlight(bufnr, ns, "ThettoSelected", i - 1, 0, -1)
    end
  end
end

return M
