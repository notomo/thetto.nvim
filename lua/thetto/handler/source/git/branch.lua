local filelib = require("thetto.lib.file")

local M = {}

M.opts = { all = false }

function M.collect(source_ctx)
  local _, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "branch", "--format", "%(refname:short)" }
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
        local is_current_branch = output == current_branch
        return {
          value = output,
          is_current_branch = is_current_branch,
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
  },
})

M.kind_name = "git/branch"

M.sorters = { "length" }

return M
