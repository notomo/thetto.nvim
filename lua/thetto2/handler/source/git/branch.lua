local filelib = require("thetto2.lib.file")

local M = {}

M.opts = { all = false }

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root(source_ctx.cwd)
  if err ~= nil then
    return nil, err
  end

  local cmd = {
    "git",
    "branch",
    "--format",
    "%(refname:short)\t%(objectname:short) %(contents:subject)",
  }
  if source_ctx.opts.all then
    table.insert(cmd, "--all")
  end

  return require("thetto2.util.job")
    .promise({ "git", "branch", "--points-at", "HEAD" }, {
      on_exit = function() end,
      cwd = source_ctx.cwd,
    })
    :next(function(heads)
      local head_output = vim.tbl_filter(function(line)
        return vim.startswith(line, "*")
      end, vim.split(heads, "\n", { plain = true }))[1]
      local current_branch = string.match(head_output, "* (.*)")
      return require("thetto2.util.job").start(cmd, source_ctx, function(output)
        local branch_name, commit_hash, message = output:match("^([^\t]+)\t(%S+) (.*)")
        local is_current_branch = branch_name == current_branch
        return {
          value = branch_name,
          commit_hash = commit_hash,
          git_root = git_root,
          desc = ("%s %s %s"):format(commit_hash, branch_name, message),
          is_current_branch = is_current_branch,
          _is_current_branch = is_current_branch and 1 or 0,
          column_offsets = {
            value = #commit_hash + 1,
            message = #commit_hash + 1 + #branch_name,
          },
        }
      end, { cwd = git_root })
    end)
end

vim.api.nvim_set_hl(0, "ThettoGitActiveBranch", { default = true, link = "Type" })

M.highlight = require("thetto2.util.highlight").columns({
  {
    group = "Comment",
    end_key = "value",
  },
  {
    group = "ThettoGitActiveBranch",
    filter = function(item)
      return item.is_current_branch
    end,
    start_key = "value",
    end_key = "message",
  },
  {
    group = "Comment",
    start_key = "message",
  },
})

M.kind_name = "git/branch"

M.behaviors = {
  cwd = require("thetto2.util.cwd").project(),
}

M.consumer_opts = {
  ui = { insert = false },
}

M.modify_pipeline = require("thetto2.util.pipeline").append({
  require("thetto2.util.sorter").fields({
    {
      name = "value",
      field_name = "_is_current_branch",
      reversed = true,
    },
    {
      name = "length",
      field_name = "value",
    },
  }),
})

return M
