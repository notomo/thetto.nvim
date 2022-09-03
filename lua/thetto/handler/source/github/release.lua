local M = {}

M.opts = { owner = ":owner", repo = ":repo" }

function M.collect(source_ctx)
  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("repos/%s/%s/releases"):format(source_ctx.opts.owner, source_ctx.opts.repo),
    "-F",
    "per_page=100",
  }
  return require("thetto.util.job").run(cmd, source_ctx, function(release)
    local mark
    if release.draft then
      mark = "D"
    else
      mark = "R"
    end
    local title = ("%s %s"):format(mark, release.name)
    local desc = ("%s %s"):format(title, release.tag_name)
    return {
      value = release.name,
      url = release.html_url,
      desc = desc,
      release = { is_draft = release.draft, tag_name = release.tag_name },
      column_offsets = { value = #mark + 1, tag_name = #title + 1 },
    }
  end, {
    to_outputs = function(job)
      return vim.json.decode(job:get_joined_stdout(), { luanil = { object = true } })
    end,
  })
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    else_group = "Character",
    end_column = 1,
    filter = function(item)
      return item.release.is_draft
    end,
  },
  {
    group = "Comment",
    start_key = "tag_name",
  },
})

M.kind_name = "url"

return M
