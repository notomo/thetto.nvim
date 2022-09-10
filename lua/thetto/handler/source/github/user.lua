local M = {}

function M.collect(source_ctx)
  local pattern, subscriber = require("thetto.util.source").get_input(source_ctx)
  if not pattern then
    return subscriber
  end

  local cmd = { "gh", "api", "-X", "GET", "search/users", "-f", "q=" .. pattern }
  return require("thetto.util.job").run(cmd, source_ctx, function(user)
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
