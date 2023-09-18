local M = {}

function M.action_edit_last_comment(items)
  local item = items[1]
  if not item then
    return nil, "no item"
  end

  local cmd = { "gh", "issue", "comment", item.url, "--editor", "--edit-last" }
  return require("thetto.util.job").promise(cmd)
end

function M.action_comment(items)
  local item = items[1]
  if not item then
    return nil, "no item"
  end

  local cmd = { "gh", "issue", "comment", item.url, "--editor" }
  return require("thetto.util.job").promise(cmd)
end

return require("thetto.core.kind").extend(M, "url")
