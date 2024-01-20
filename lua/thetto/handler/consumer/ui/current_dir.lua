local M = {}

function M.apply(window_id, cwd)
  vim.api.nvim_win_call(window_id, function()
    local ok, result = pcall(require("thetto.lib.file").lcd, cwd)
    if not ok then
      vim.notify("[thetto] " .. result, vim.log.levels.WARN)
    end
  end)
end

return M
