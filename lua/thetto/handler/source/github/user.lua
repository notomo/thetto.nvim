local M = {}

function M.get_pattern()
  return vim.fn.input("Pattern: ")
end

function M.collect(source_ctx)
  local pattern = source_ctx.pattern
  if pattern == "" then
    return {}
  end

  local cmd = { "gh", "api", "-X", "GET", "search/users", "-f", "q=" .. pattern }
  return require("thetto.util.job")
    .promise(cmd, {
      cwd = source_ctx.cwd,
      on_exit = function() end,
    })
    :next(function(output)
      local users = vim.json.decode(output, { luanil = { object = true } }).items
      return vim
        .iter(users)
        :map(function(user)
          return {
            value = user.login,
            url = user.html_url,
            user = { name = user.login, is_org = user.type == "Organization" },
          }
        end)
        :totable()
    end)
end

M.kind_name = "github/user"

M.modify_pipeline = require("thetto.util.pipeline").prepend({
  require("thetto.util.filter").by_name("source_input"),
})

return M
