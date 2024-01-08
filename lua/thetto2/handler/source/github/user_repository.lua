local M = {}

M.opts = { owner = ":owner", is_org = false }

function M.collect(source_ctx)
  local typ = "users"
  if source_ctx.opts.is_org then
    typ = "orgs"
  end

  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("%s/%s/repos"):format(typ, source_ctx.opts.owner),
    "-F",
    "per_page=100",
    "-F",
    "sort=updated",
  }
  return require("thetto2.util.job").run(cmd, source_ctx, function(repo)
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
      return vim.json.decode(output, { luanil = { object = true } })
    end,
  })
end

M.highlight = require("thetto2.util.highlight").columns({
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
