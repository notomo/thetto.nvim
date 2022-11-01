local M = {}

function M.render_diff(bufnr, item)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "diff"
  local cmd = { "git", "--no-pager", "show", "--date=iso", item.commit_hash or item.stash_name }
  return require("thetto.util.job").promise(cmd, {
    on_exit = function(output)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      local lines = vim.split(output, "\n", true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end,
  })
end

function M.open_diff(items, f)
  local promises = {}
  for _, item in ipairs(items) do
    local bufnr = vim.api.nvim_create_buf(false, true)
    local promise = M.render_diff(bufnr, item)
    table.insert(promises, promise)
    f(bufnr)
  end
  return require("thetto.vendor.promise").all(promises)
end

return M
