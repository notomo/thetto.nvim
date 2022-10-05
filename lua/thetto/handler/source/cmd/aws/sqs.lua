local M = {}

M.opts = { profile = nil }

function M.collect(source_ctx)
  local cmd = { "aws", "sqs", "list-queues" }
  return require("thetto.util.job").run(cmd, source_ctx, function(url)
    return {
      value = url,
    }
  end, {
    to_outputs = function(job)
      return vim.json.decode(job:get_joined_stdout(), { luanil = { object = true } }).QueueUrls
    end,
    env = {
      AWS_PROFILE = source_ctx.opts.profile,
    },
  })
end

M.kind_name = "word"

M.actions = {
  action_inspect = function(items)
    return vim.tbl_map(function(item)
      local cmd = { "aws", "sqs", "get-queue-attributes", "--queue-url", item.value, "--attribute-names=All" }
      return require("thetto.util.job").promise(cmd)
    end, items)
  end,
}

return M
