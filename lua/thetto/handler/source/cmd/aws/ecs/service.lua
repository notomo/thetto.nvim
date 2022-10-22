local M = {}

M.opts = {
  profile = nil,
  cluster = "default",
}

function M.collect(source_ctx)
  local cmd = { "aws", "ecs", "list-services", "--cluster", source_ctx.opts.cluster }
  return require("thetto.util.job")
    .promise(cmd, {
      cwd = source_ctx.cwd,
      env = {
        AWS_PROFILE = source_ctx.opts.profile,
      },
      on_exit = function() end,
    })
    :next(function(output)
      local arns = vim.json.decode(output, { luanil = { object = true } }).serviceArns
      return vim.tbl_map(function(arn)
        return {
          value = arn,
          cluster = source_ctx.opts.cluster,
        }
      end, arns)
    end)
end

M.actions = {
  action_list_children = function(items)
    local item = items[1]
    if not item then
      return
    end
    return require("thetto").start("cmd/aws/ecs/task", {
      source_opts = {
        cluster = item.cluster,
        service = item.value,
      },
    })
  end,
}

M.kind_name = "word"

return M
