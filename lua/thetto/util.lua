local M = {}

local find_module = function(path)
  local ok, module = pcall(require, path)
  if not ok then
    return nil
  end
  return module
end

M.find_source = function(name)
  return find_module("thetto/source/" .. name)
end

M.find_kind = function(name)
  return find_module("thetto/kind/" .. name)
end

M.close_window = function(id)
  if id == "" then
    return
  end
  if not vim.api.nvim_win_is_valid(id) then
    return
  end
  vim.api.nvim_win_close(id, true)
end

M.debounce = function(ms, f)
  local timer = nil
  return function()
    if timer == nil then
      timer = vim.loop.new_timer()
    end
    timer:stop()
    timer:start(ms, 0, vim.schedule_wrap(f))
  end
end

return M
