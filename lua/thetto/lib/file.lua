local vim = vim

local M = {}

local fs_access = vim.uv.fs_access
function M.readable(file_path)
  return fs_access(file_path, "R")
end

function M.create_if_need(file_path)
  local dir_path = vim.fs.dirname(file_path)
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
  if not f then
    error("cannot write: " .. path)
  end
  for _, line in ipairs(lines) do
    f:write(line .. "\n")
  end
  f:close()
end

function M.find_git_root(cwd)
  local git_root = vim.fs.root(cwd or ".", { ".git" })
  if git_root == nil then
    return nil, "not found .git"
  end
  return git_root, nil
end

function M.lcd(path)
  vim.fn.chdir(path, "window")
end

function M.read_all(path)
  local f = io.open(path, "r")
  if not f then
    return { message = "cannot read: " .. path }
  end
  if vim.fn.isdirectory(path) == 1 then
    return { message = "directory: " .. path }
  end
  local str = f:read("*a")
  f:close()
  return str
end

return M
