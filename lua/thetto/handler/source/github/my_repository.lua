local M = {}

function M.collect(source_ctx)
  local cmd =
    { "gh", "repo", "list", "--limit=1000", "--json=url,owner,name,nameWithOwner,isArchived,isPrivate,isFork" }
  return require("thetto.util.job").run(cmd, source_ctx, function(repo)
    local mark
    if repo.isArchived then
      mark = "A"
    else
      mark = " "
    end
    if repo.isPrivate then
      mark = mark .. "P"
    else
      mark = mark .. " "
    end
    if repo.isFork then
      mark = mark .. "F"
    else
      mark = mark .. " "
    end
    local title = ("%s %s"):format(mark, repo.nameWithOwner)
    return {
      value = repo.nameWithOwner,
      desc = title,
      url = repo.url,
      repo = {
        owner = repo.owner.login,
        name = repo.name,
        is_archived = repo.isArchived,
        is_private = repo.isPrivate,
        is_fork = repo.isFork,
      },
      column_offsets = { value = #mark + 1 },
    }
  end, {
    to_outputs = function(job)
      return vim.json.decode(job:get_joined_stdout(), { luanil = { object = true } })
    end,
  })
end

M.kind_name = "github/repository"

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    end_column = 1,
    filter = function(item)
      return item.repo.is_archived
    end,
  },
  {
    group = "Label",
    start_column = 1,
    end_column = 2,
    filter = function(item)
      return item.repo.is_private
    end,
  },
  {
    group = "Comment",
    start_column = 2,
    end_column = 3,
    filter = function(item)
      return item.repo.is_fork
    end,
  },
})

return M
