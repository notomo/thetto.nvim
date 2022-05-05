local M = {}

function M.collect()
  local items = {}
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({})) do
    local parts = {}
    if autocmd.group_name then
      table.insert(parts, autocmd.group_name)
    end

    table.insert(parts, autocmd.event)
    table.insert(parts, autocmd.pattern)

    if autocmd.once then
      table.insert(parts, "++once")
    end

    if autocmd.command then
      table.insert(parts, autocmd.command)
    elseif autocmd.desc then
      table.insert(parts, autocmd.desc)
    end

    table.insert(items, {
      value = table.concat(parts, " "),
      autocmd = autocmd,
    })
  end
  return items
end

M.kind_name = "vim/autocmd"

return M
