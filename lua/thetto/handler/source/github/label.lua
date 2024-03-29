local M = {}

M.opts = { owner = ":owner", repo = ":repo" }

function M.collect(source_ctx)
  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("repos/%s/%s/labels"):format(source_ctx.opts.owner, source_ctx.opts.repo),
    "-F",
    "per_page=100",
  }
  return require("thetto.util.job").run(cmd, source_ctx, function(label)
    local name = label.name
    local label_desc = label.description
    if not label_desc then
      label_desc = ""
    end
    local desc = ("%s %s"):format(name, label_desc)
    return {
      value = label.name,
      desc = desc,
      label = { owner = source_ctx.opts.owner, repo = source_ctx.opts.repo },
      column_offsets = { value = 0, description = #name + 1 },
    }
  end, {
    to_outputs = function(output)
      return vim.json.decode(output, { luanil = { object = true } })
    end,
  })
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    start_key = "description",
  },
})

M.kind_name = "github/label"

return M
