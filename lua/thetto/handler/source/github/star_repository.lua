local M = {}

function M.collect(source_ctx)
  local cmd = { "gh", "api", "-X", "GET", "user/starred", "-F", "per_page=100" }
  --- @async
  local collect = function()
    local output = require("thetto.util.job").await(cmd, {
      cwd = source_ctx.cwd,
      on_exit = function() end,
    })
    local repos = vim.json.decode(output, { luanil = { object = true } })
    return vim
      .iter(repos)
      :map(function(repo)
        return {
          value = repo.full_name,
          url = repo.html_url,
          repo = { owner = repo.owner.login, name = repo.name },
        }
      end)
      :totable()
  end
  return vim.async.run(collect)
end

M.kind_name = "github/repository"

return M
