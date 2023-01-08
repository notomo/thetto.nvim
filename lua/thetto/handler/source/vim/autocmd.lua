local M = {}

M.opts = {
  buffer = nil,
}

function M.collect(source_ctx)
  local items = {}

  local buffer = source_ctx.opts.buffer == 0 and vim.api.nvim_get_current_buf() or source_ctx.opts.buffer
  local autocmds = vim.api.nvim_get_autocmds({
    buffer = buffer,
  })
  for _, autocmd in ipairs(autocmds) do
    local parts = {}
    if autocmd.group_name then
      table.insert(parts, autocmd.group_name)
    end

    table.insert(parts, autocmd.event)
    table.insert(parts, autocmd.pattern)

    if autocmd.once then
      table.insert(parts, "++once")
    end

    if autocmd.command ~= "" then
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
