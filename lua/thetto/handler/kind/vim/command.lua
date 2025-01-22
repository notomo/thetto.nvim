local M = {}

function M.action_execute(items)
  for _, item in ipairs(items) do
    local ok, err = pcall(function()
      vim.cmd(item.value)
    end)
    if not ok then
      return err
    end
  end
end

M.default_action = "execute"

return M
