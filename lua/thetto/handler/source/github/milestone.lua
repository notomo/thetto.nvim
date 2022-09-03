local M = {}

M.opts = { owner = ":owner", repo = ":repo" }

function M.collect(source_ctx)
  local cmd = {
    "gh",
    "api",
    "-X",
    "GET",
    ("repos/%s/%s/milestones"):format(source_ctx.opts.owner, source_ctx.opts.repo),
    "-F",
    "per_page=100",
    "-F",
    "state=all",
  }
  return require("thetto.util.job").run(cmd, source_ctx, function(milestone)
    local mark
    if milestone.state == "open" then
      mark = "O"
    else
      mark = "C"
    end

    local milestone_title = milestone.title

    local milestone_desc = milestone.description
    if not milestone_desc then
      milestone_desc = ""
    end
    milestone_desc = milestone_desc:gsub("\n", " "):gsub("\r", " ")

    local title = ("%s %s %s"):format(mark, milestone_title, milestone_desc)
    local desc = title
    return {
      value = milestone.title,
      url = milestone.html_url,
      desc = desc,
      milestone = {
        is_opened = milestone.state == "open",
        number = milestone.number,
        owner = source_ctx.opts.owner,
        repo = source_ctx.opts.repo,
      },
      column_offsets = { value = #mark + 1, description = #mark + #milestone_title + 1 },
    }
  end, {
    to_outputs = function(job)
      return vim.json.decode(job:get_joined_stdout(), { luanil = { object = true } })
    end,
  })
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Character",
    else_group = "Boolean",
    end_column = 1,
    filter = function(item)
      return item.milestone.is_opened
    end,
  },
  {
    group = "Comment",
    start_key = "description",
  },
})

M.kind_name = "github/milestone"

return M
