local M = {}

function M.action_checkout(items)
  local item = items[1]
  if not item then
    return nil, "no item"
  end

  local cmd = { "gh", "pr", "checkout", item.url }
  return require("thetto2.util.job").promise(cmd)
end

return require("thetto2.core.kind").extend(M, "url")
