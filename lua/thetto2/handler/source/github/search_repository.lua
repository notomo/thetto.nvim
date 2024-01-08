local M = {}

function M.collect(source_ctx)
  local pattern, subscriber = require("thetto2.util.source").get_input(source_ctx)
  if not pattern then
    return subscriber
  end

  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    "search/repositories",
    "-F",
    "q=" .. pattern,
    "-F",
    "per_page=100",
  }
  return require("thetto.util.job").run(cmd, source_ctx, function(repo)
    local mark
    if repo.archived then
      mark = "A"
    else
      mark = " "
    end
    local title = ("%s %s"):format(mark, repo.full_name)
    local desc = title
    return {
      value = repo.full_name,
      url = repo.html_url,
      desc = desc,
      repo = { is_archived = repo.archived, owner = repo.owner.login, name = repo.name },
      column_offsets = { value = #mark + 1 },
    }
  end, {
    to_outputs = function(output)
      local data = vim.json.decode(output, { luanil = { object = true } })
      return data.items
    end,
  })
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    end_column = 1,
    filter = function(item)
      return item.repo.is_archived
    end,
  },
})

M.kind_name = "github/repository"

M.modify_pipeline = require("thetto2.util.pipeline").prepend({
  require("thetto2.util.filter").by_name("source_input"),
})

return M
