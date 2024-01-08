local M = {}

function M.collect(source_ctx)
  local cmd = { "gh", "api", "-X", "GET", "user/starred", "-F", "per_page=100" }
  return require("thetto2.util.job")
    .promise(cmd, {
      cwd = source_ctx.cwd,
      on_exit = function() end,
    })
    :next(function(output)
      local repos = vim.json.decode(output, { luanil = { object = true } })
      return vim.tbl_map(function(repo)
        return {
          value = repo.full_name,
          url = repo.html_url,
          repo = { owner = repo.owner.login, name = repo.name },
        }
      end, repos)
    end)
end

M.kind_name = "github/repository"

return M
