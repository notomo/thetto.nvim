local M = {}

function M.collect(source_ctx)
  local cmd = {
    "gh",
    "projects",
    "list",
    "--format=json",
  }
  return require("thetto2.util.job").run(cmd, source_ctx, function(project)
    local value = ("%s %s"):format(project.title, project.url)
    return {
      value = value,
      url = project.url,
      project = project,
    }
  end, {
    to_outputs = function(output)
      return vim.json.decode(output, { luanil = { object = true } }).projects
    end,
  })
end

M.kind_name = "url"

return M
