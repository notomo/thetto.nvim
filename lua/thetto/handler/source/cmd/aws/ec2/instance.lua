local M = {}

M.opts = { profile = nil }

function M.collect(source_ctx)
  local cmd = { "aws", "ec2", "describe-instances", "--no-cli-pager" }
  return require("thetto.util.job")
    .promise(cmd, {
      cwd = source_ctx.cwd,
      env = {
        AWS_PROFILE = source_ctx.opts.profile,
      },
      on_exit = function() end,
    })
    :next(function(output)
      local reservations = vim.json.decode(output, { luanil = { object = true } }).Reservations
      local items = {}
      for _, reservation in ipairs(reservations) do
        for _, instance in ipairs(reservation.Instances) do
          table.insert(items, {
            value = instance.KeyName,
            reservations = reservations,
          })
        end
      end
      return items
    end)
end

M.kind_name = "word"

return M
