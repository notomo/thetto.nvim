local M = {}

function M.collect(source_ctx)
  local pattern, subscriber = require("thetto.util.source").get_input(source_ctx)
  if not pattern then
    return subscriber
  end

  local cmd = { "gh", "api", "-X", "GET", "search/users", "-f", "q=" .. pattern }
  return require("thetto.util.job")
    .promise(cmd, {
      cwd = source_ctx.cwd,
      on_exit = function() end,
    })
    :next(function(output)
      local users = vim.json.decode(output, { luanil = { object = true } }).items
      return vim.tbl_map(function(user)
        return {
          value = user.login,
          url = user.html_url,
          user = { name = user.login, is_org = user.type == "Organization" },
        }
      end, users)
    end)
end

M.kind_name = "github/user"

M.filters = require("thetto.util.filter").prepend("interactive")

return M
