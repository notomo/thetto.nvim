local M = {}

function M.action_open_browser(items)
  local errs = {}
  for _, item in ipairs(items) do
    local url = item.url
    if not vim.startswith(url, "http") then
      table.insert(errs, "invalid url: " .. url)
    else
      vim.ui.open(url)
    end
  end
  if #errs == 0 then
    return
  end
  return nil, table.concat(errs, "\n")
end

M.default_action = "open_browser"

return M
