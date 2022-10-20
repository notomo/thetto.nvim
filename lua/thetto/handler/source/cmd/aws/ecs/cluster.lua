local M = {}

M.opts = { profile = nil }

function M.collect(source_ctx)
  local cmd = { "aws", "ecs", "list-clusters" }
  return require("thetto.util.job")
    .promise(cmd, {
      cwd = source_ctx.cwd,
      env = {
        AWS_PROFILE = source_ctx.opts.profile,
      },
      on_exit = function() end,
    })
    :next(function(output)
      local arns = vim.json.decode(output, { luanil = { object = true } }).clusterArns
      return vim.tbl_map(function(arn)
        return {
          value = arn,
        }
      end, arns)
    end)
end

M.kind_name = "word"

return M
