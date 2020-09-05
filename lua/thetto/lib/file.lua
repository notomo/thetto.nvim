local M = {}

M.readable = function(file_path)
  return vim.fn.filereadable(file_path) ~= 0
end

M.create_if_need = function(file_path)
  local dir_path = vim.fn.fnamemodify(file_path, ":h")
  if vim.fn.isdirectory(dir_path) == 0 then
    vim.fn.mkdir(dir_path, "p")
  end
  if M.readable(file_path) then
    return false
  end
  io.open(file_path, "w"):close()
  return true
end

M.read_lines = function(path, s, e)
  local f = io.open(path, "r")
  local lines = {}
  local read = f:lines()
  for _ = 1, s - 1, 1 do
    read() -- skip
  end
  for _ = s, e, 1 do
    table.insert(lines, read())
  end
  io.close(f)
  return lines
end

return M
