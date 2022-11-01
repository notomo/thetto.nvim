local M = {}

function M.conclusion_mark(e)
  if e.conclusion == "success" then
    return "✅"
  elseif e.conclusion == "failure" then
    return "❌"
  elseif e.conclusion == "skipped" then
    return "🔽"
  elseif e.conclusion == "cancelled" then
    return "🚫"
  elseif e.status == "in_progress" then
    return "🏃"
  end
  return "  "
end

function M.state(e)
  local states = { e.status }
  if e.conclusion then
    table.insert(states, e.conclusion)
  end
  return ("(%s)"):format(table.concat(states, ","))
end

return M
