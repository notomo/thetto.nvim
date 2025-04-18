local filelib = require("thetto.lib.file")

local M = {}

M.opts = {
  args = {},
  path = nil,
}

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root(source_ctx.cwd)
  if err ~= nil then
    return err
  end

  local cmd = {
    "git",
    "--no-pager",
    "log",
    "--pretty=format:%h\t\t<%an>\t\t<%s>\t\t<%d>",
  }
  vim.list_extend(cmd, source_ctx.opts.args)
  vim.list_extend(cmd, { "--", source_ctx.opts.path })
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local commit_hash, user_name, message, branch_info = output:match("^(%S+)\t\t(<.*>)\t\t<(.*)>\t\t<(.*)>")
    if not commit_hash then
      return nil
    end
    local value = ("%s %s %s%s"):format(commit_hash, message, user_name, branch_info)
    return {
      value = value,
      commit_hash = commit_hash,
      git_root = git_root,
      column_offsets = {
        commit_hash = 0,
        message = #commit_hash + 1,
        user_name = #commit_hash + 1 + #message + 1,
        branch_info = #commit_hash + 1 + #message + 1 + #user_name + 1,
      },
      path = source_ctx.opts.path,
    }
  end, { cwd = git_root })
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    end_key = "message",
  },
  {
    group = "Label",
    start_key = "user_name",
    end_key = "branch_info",
  },
  {
    group = "Conditional",
    start_key = "branch_info",
  },
})

M.kind_name = "git/commit"

M.cwd = require("thetto.util.cwd").project()

M.consumer_opts = {
  ui = { insert = false },
}

return M
