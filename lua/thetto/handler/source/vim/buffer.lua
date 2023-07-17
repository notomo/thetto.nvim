local M = {}

M.opts = { buftype = nil }

function M.collect(source_ctx)
  return vim
    .iter(vim.api.nvim_list_bufs())
    :map(function(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      if not vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype ~= "terminal" then
        return
      end
      if source_ctx.opts.buftype ~= nil and vim.bo[bufnr].buftype ~= source_ctx.opts.buftype then
        return
      end

      local name = vim.api.nvim_buf_get_name(bufnr)
      if name == "" then
        name = "(None)"
      end

      local modified_marker = " "
      if vim.bo[bufnr].modified then
        modified_marker = "+"
      end

      local _desc = ("%s%3d "):format(modified_marker, bufnr)
      local desc = ("%s%s"):format(_desc, name)
      return {
        desc = desc,
        value = name,
        bufnr = bufnr,
        column_offsets = { value = #_desc },
      }
    end)
    :totable()
end

M.kind_name = "vim/buffer"

return M
