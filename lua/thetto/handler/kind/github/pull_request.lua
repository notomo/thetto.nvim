local M = {}

function M.action_checkout(items)
  local item = items[1]
  if not item then
    return "no item"
  end

  local cmd = { "gh", "pr", "checkout", item.url }
  return require("thetto.util.job").promise(cmd)
end

return require("thetto.core.kind").extend(M, "url")
