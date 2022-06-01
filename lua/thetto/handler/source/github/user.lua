local M = {}

function M.collect(_, source_ctx)
  local pattern = source_ctx.pattern
  if not pattern then
    pattern = vim.fn.input("Pattern: ")
  end
  if not pattern or pattern == "" then
    return function(observer)
      observer:complete()
    end
  end

  local cmd = { "gh", "api", "-X", "GET", "search/users", "-f", "q=" .. pattern }
  return require("thetto.util").job.run(cmd, source_ctx, function(user)
    return {
      value = user.login,
      url = user.html_url,
      user = { name = user.login, is_org = user.type == "Organization" },
    }
  end, {
    to_outputs = function(job)
      local data = vim.json.decode(job:get_joined_stdout(), { luanil = { object = true } })
      return data.items
    end,
  })
end

M.kind_name = "github/user"

return M
