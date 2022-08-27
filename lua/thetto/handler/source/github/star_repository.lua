local M = {}

function M.collect(_, source_ctx)
  local cmd = { "gh", "api", "-X", "GET", "user/starred", "-F", "per_page=100" }
  return require("thetto.util.job").run(cmd, source_ctx, function(repo)
    return {
      value = repo.full_name,
      url = repo.html_url,
      repo = { owner = repo.owner.login, name = repo.name },
    }
  end, {
    to_outputs = function(job)
      return vim.json.decode(job:get_joined_stdout(), { luanil = { object = true } })
    end,
  })
end

M.kind_name = "github/repository"

return M
