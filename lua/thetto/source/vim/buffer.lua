local M = {}

M.collect = function()
  local items = {}
  local bufnrs = vim.api.nvim_list_bufs()
  for _, bufnr in ipairs(bufnrs) do
    if not vim.api.nvim_buf_is_valid(bufnr) then
      goto continue
    end

    local listed = vim.api.nvim_buf_get_option(bufnr, "buflisted")
    if listed == 0 then
      goto continue
    end

    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
      name = "(None)"
    end

    local modified = vim.api.nvim_buf_get_option(bufnr, "modified")
    local modified_marker = " "
    if modified then
      modified_marker = "+"
    end

    local _desc = ("%s%3d "):format(modified_marker, bufnr)
    local desc = ("%s%s"):format(_desc, name)
    table.insert(items, {
      desc = desc,
      value = name,
      bufnr = bufnr,
      column_offsets = {value = #_desc},
    })
    ::continue::
  end
  return items
end

M.kind_name = "vim/buffer"

return M
