local M = {}

M.opts = {
  profile = nil,
}

function M.collect(source_ctx)
  local cmd = { "aws", "sqs", "list-queues" }
  return require("thetto.util.job")
    .promise(cmd, {
      cwd = source_ctx.cwd,
      env = {
        AWS_PROFILE = source_ctx.opts.profile,
      },
      on_exit = function() end,
    })
    :next(function(output)
      local urls = vim.json.decode(output, { luanil = { object = true } }).QueueUrls
      return vim.tbl_map(function(url)
        return {
          value = url,
        }
      end, urls)
    end)
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
