local filelib = require("thetto.lib.file")

local M = {}

M.opts = { all = false }

function M.collect(source_ctx)
  local _, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "branch", "--format", "%(refname:short) %(contents:subject)" }
  if source_ctx.opts.all then
    table.insert(cmd, "--all")
  end

  return require("thetto.util.job")
    .promise({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, {
      on_exit = function() end,
      cwd = source_ctx.cwd,
    })
    :next(function(current_branch)
      current_branch = vim.trim(current_branch)
      return require("thetto.util.job").start(cmd, source_ctx, function(output)
        local branch_name = output:match("(%S+) (.*)")
        local is_current_branch = branch_name == current_branch
        return {
          value = branch_name,
          desc = output,
          is_current_branch = is_current_branch,
          column_offsets = {
            value = 0,
            message = #branch_name,
          },
        }
      end)
    end)
end

vim.api.nvim_set_hl(0, "ThettoGitActiveBranch", { default = true, link = "Type" })

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "ThettoGitActiveBranch",
    filter = function(item)
      return item.is_current_branch
    end,
    end_key = "message",
  },
  {
    group = "Comment",
    start_key = "message",
  },
})

M.kind_name = "git/branch"

M.sorters = { "length" }

return M
