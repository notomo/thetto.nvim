local M = {}

function M.diff(bufnr, cmd)
  local git_root, err = require("thetto.lib.file").find_git_root()
  if err then
    return require("thetto.vendor.promise").reject(err)
  end
  cmd = cmd or { "git", "--no-pager", "diff", "--date=iso" }
  return require("thetto.util.job")
    .promise(cmd, {
      cwd = git_root,
      on_exit = function() end,
    })
    :next(function(output)
      local lines = vim.split(output, "\n", true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end)
end

function M.diff_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "diff"
  return bufnr
end

return M
