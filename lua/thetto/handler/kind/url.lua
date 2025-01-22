local M = {}

M.opts = {}

M.opts.open_browser = {
  open = function(url)
    if not vim.startswith(url, "http") then
      return "invalid url: " .. url
    end
    vim.ui.open(url)
  end,
}
function M.action_open_browser(items, action_ctx)
  local errs = {}
  for _, item in ipairs(items) do
    local err = action_ctx.opts.open(item.url)
    if err then
      table.insert(errs, err)
    end
  end
  if #errs == 0 then
    return
  end
  return table.concat(errs, "\n")
end

M.default_action = "open_browser"

return M
