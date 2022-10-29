local M = {}

M.opts = { owner = ":owner", repo = ":repo" }

function M.collect(source_ctx)
  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("repos/%s/%s/projects"):format(source_ctx.opts.owner, source_ctx.opts.repo),
    "-F",
    "per_page=100",
    "-F",
    "state=open",
    "-H",
    "Accept: application/vnd.github.inertia-preview+json",
  }
  return require("thetto.util.job").run(cmd, source_ctx, function(project)
    local mark
    if project.state == "open" then
      mark = "O"
    else
      mark = "C"
    end

    local project_name = project.name

    local project_desc = project.body:gsub("\n", " "):gsub("\r", " ")
    if not project_desc then
      project_desc = ""
    end

    local desc = ("%s %s %s"):format(mark, project_name, project_desc)
    return {
      value = project.name,
      url = project.html_url,
      desc = desc,
      project = {
        is_opened = project.state == "open",
        id = project.id,
        owner = source_ctx.opts.owner,
        repo = source_ctx.opts.repo,
      },
      column_offsets = { value = #mark + 1, description = #mark + #project_name + 1 },
    }
  end, {
    to_outputs = function(output)
      return vim.json.decode(output, { luanil = { object = true } })
    end,
  })
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Character",
    else_group = "Boolean",
    end_column = 1,
    filter = function(item)
      return item.project.is_opened
    end,
  },
  {
    group = "Comment",
    start_key = "description",
  },
})

M.kind_name = "url"

return M
