local M = {}

function M.action_execute(_, items)
  for _, item in ipairs(items) do
    local ok, err = pcall(vim.cmd, item.value)
    if not ok then
      return nil, err
    end
  end
end

M.default_action = "execute"

return M
