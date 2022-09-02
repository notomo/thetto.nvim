local filelib = require("thetto.lib.file")

local M = {}

M.opts = { all = false }

function M.collect(self, source_ctx)
  local _, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "branch", "--format", "%(refname:short)" }
  if self.opts.all then
    table.insert(cmd, "--all")
  end

  local current_branch = nil
  local get_current_job, joberr = require("thetto.util.job").execute({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, {
    on_exit = function(job_self)
      current_branch = job_self:get_stdout()[1]
    end,
    cwd = source_ctx.cwd,
  })
  if joberr ~= nil then
    return nil, joberr
  end
  get_current_job:wait(1000)

  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local is_current_branch = output == current_branch
    return {
      value = output,
      is_current_branch = is_current_branch,
    }
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
