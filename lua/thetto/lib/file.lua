local vim = vim

local M = {}

function M.readable(file_path)
  return vim.fn.filereadable(file_path) ~= 0
end

function M.create_if_need(file_path)
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

function M.read_lines(path, s, e)
  local f = io.open(path, "r")
  if f == nil then
    return {}
  end

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

function M.write_lines(path, lines)
  local f = io.open(path, "w")
  for _, line in ipairs(lines) do
    f:write(line .. "\n")
  end
  f:close()
end

function M.find_upward_dir(child_pattern)
  local found_file = vim.fn.findfile(child_pattern, ".;")
  if found_file ~= "" then
    return vim.fn.fnamemodify(found_file, ":p:h")
  end

  local found_dir = vim.fn.finddir(child_pattern, ".;")
  if found_dir ~= "" then
    return vim.fn.fnamemodify(found_dir, ":p:h:h")
  end

  return nil
end

function M.find_git_root()
  local git_root = M.find_upward_dir(".git")
  if git_root == nil then
    return nil, "not found .git"
  end
  return git_root, nil
end

function M.escape(path)
  return ([[`='%s'`]]):format(path:gsub("'", "''"))
end

return M
