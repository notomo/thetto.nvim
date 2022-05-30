local M = {}

function M.collect(self, source_ctx)
  local pattern = source_ctx.pattern
  if not pattern then
    pattern = vim.fn.input("Pattern: ")
  end
  if not pattern or pattern == "" then
    return {}, nil, self.errors.skip_empty_pattern
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
  return require("thetto.util").job.run(cmd, source_ctx, function(repo)
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
    to_outputs = function(job)
      return vim.json.decode(job:get_joined_stdout(), { luanil = { object = true } })
    end,
  })
end

M.highlight = require("thetto.util").highlight.columns({
  {
    group = "Comment",
    end_column = 1,
    filter = function(item)
      return item.repo.is_archived
    end,
  },
})

M.kind_name = "github/repository"

return M
