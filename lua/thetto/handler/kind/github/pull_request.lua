local M = {}

function M.action_checkout(_, items)
  local item = items[1]
  if not item then
    return nil, "no item"
  end

  local cmd = { "gh", "pr", "checkout", item.url }
  return require("thetto.util.job").execute(cmd)
end

return require("thetto.core.kind").extend(M, "url")
