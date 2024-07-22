local M = {}

M.opts = {
  buffer = false,
}

function M.collect(source_ctx)
  local buffer = source_ctx.opts.buffer and source_ctx.bufnr or nil
  local autocmds = vim.api.nvim_get_autocmds({
    buffer = buffer,
  })
  return vim
    .iter(autocmds)
    :map(function(autocmd)
      local desc = ""
      if autocmd.command ~= "" then
        desc = autocmd.command
      elseif autocmd.desc then
        desc = autocmd.desc
      end
      return {
        value = vim
          .iter({
            autocmd.group_name ~= nil and autocmd.group_name or "",
            autocmd.event,
            autocmd.pattern,
            autocmd.once and "++once" or "",
            desc ~= nil and desc,
          })
          :filter(function(part)
            return part ~= ""
          end)
          :join(" "),
        autocmd = autocmd,
      }
    end)
    :totable()
end

M.kind_name = "vim/autocmd"

return M
