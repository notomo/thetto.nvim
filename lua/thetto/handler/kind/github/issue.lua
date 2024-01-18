local M = {}

M.opts = {}

function M.action_edit_last_comment(items)
  local item = items[1]
  if not item then
    return nil, "no item"
  end

  local cmd = { "gh", "issue", "comment", item.url, "--editor", "--edit-last" }
  return require("thetto.util.job").execute(cmd)
end

function M.action_comment(items)
  local item = items[1]
  if not item then
    return nil, "no item"
  end

  local cmd = { "gh", "issue", "comment", item.url, "--editor" }
  return require("thetto.util.job").execute(cmd)
end

M.opts.close = {
  reason = "completed",
  comment = "",
}
function M.action_close(items, action_ctx)
  local item = items[1]
  if not item then
    return nil, "no item"
  end

  local cmd = { "gh", "issue", "close", item.url, "--reason", action_ctx.opts.reason }
  if action_ctx.opts.comment ~= "" then
    table.insert(cmd, "--comment=" .. action_ctx.opts.comment)
  end

  return require("thetto.util.job").execute(cmd)
end

function M.action_close_with_comment(items, action_ctx)
  return require("thetto.util.input")
    .promise({
      prompt = "Comment: ",
    })
    :next(function(input)
      if not input or input == "" then
        return require("thetto.vendor.misclib.message").info("Canceled issue close with comment")
      end
      return require("thetto.util.action").call(action_ctx.kind_name, "close", items, {
        comment = input,
      })
    end)
end

function M.action_close_not_planned(items, action_ctx)
  return require("thetto.util.action").call(action_ctx.kind_name, "close", items, {
    reason = { "not planned" },
  })
end

function M.action_reopen(items)
  local item = items[1]
  if not item then
    return nil, "no item"
  end

  local cmd = { "gh", "issue", "reopen", item.url }
  return require("thetto.util.job").execute(cmd)
end

function M.action_list_comment(items)
  for _, item in ipairs(items) do
    local source = require("thetto.util.source").by_name("github/issue_comment", {
      opts = {
        url = item.url,
      },
    })
    return require("thetto").start(source)
  end
end

M.action_list_children = M.action_list_comment

return require("thetto.core.kind").extend(M, "url")
