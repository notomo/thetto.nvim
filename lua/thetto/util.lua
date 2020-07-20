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

M.find_iteradapter = function(name)
  return find_module("thetto/iteradapter/" .. name)
end

M.find_target = function(name)
  return find_module("thetto/target/" .. name)
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

M.create_buffer = function(name, modify)
  local pattern = ("^%s$"):format(name)
  local bufnr = vim.fn.bufnr(pattern)
  if bufnr ~= -1 then
    vim.api.nvim_command(bufnr .. "bwipeout!")
  end
  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, name)
  modify(bufnr)
  return bufnr
end

M.buffer_var = function(bufnr, name)
  local ok, var = pcall(vim.api.nvim_buf_get_var, bufnr, name)
  if not ok then
    return nil
  end
  return var
end

M.uniq = function(list)
  local hash = {}
  local new_list = {}
  for _, v in ipairs(list) do
    if not hash[v] then
      new_list[#new_list + 1] = v
      hash[v] = true
    end
  end
  return new_list
end

M.print_err = function(err)
  vim.api.nvim_err_write(err .. "\n")
end

return M
