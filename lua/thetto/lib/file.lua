local M = {}

M.create_if_need = function(file_path)
  local dir_path = vim.fn.fnamemodify(file_path, ":h")
  if vim.fn.isdirectory(dir_path) == 0 then
    vim.fn.mkdir(dir_path, "p")
  end
  if vim.fn.filereadable(file_path) ~= 0 then
    return false
  end
  io.open(file_path, "w"):close()
  return true
end

return M
