local M = {}

local _dedup_sep
if vim.uv.os_uname().version:match("Windows") then
  _dedup_sep = function(path)
    return (path:gsub("[/\\][/\\]*", "/"))
  end
else
  _dedup_sep = function(path)
    return (path:gsub("//+", "/"))
  end
end

local function join(...)
  -- don't use vim.fs to use in uv.nw_thread
  local n = select("#", ...)
  local segments = {}
  for i = 1, n do
    local s = select(i, ...)
    if s and #s > 0 then
      segments[#segments + 1] = s
    end
  end
  local path = table.concat(segments, "/")
  return _dedup_sep(path)
end

local function normalize(path)
  -- don't use vim.fs to use in uv.nw_thread
  local x = path:gsub("\\", "/")
  return x
end

local function abspath(path)
  -- don't use vim.fs to use in uv.nw_thread
  path = normalize(path)

  if vim.startswith(path, "/") then
    return path
  end

  local cwd = M.normalize(vim.uv.cwd())
  if path == "." then
    return cwd
  end
  return join(cwd, path)
end

function M.to_relative(path, base_path)
  -- don't use vim.fs to use in uv.nw_thread
  path = normalize(abspath(path))
  base_path = normalize(abspath(base_path))
  if path == base_path then
    return "."
  end
  base_path = base_path .. (path ~= "/" and "/" or "")
  return vim.startswith(path, base_path) and path:sub(#base_path + 1) or path
end

function M.parse_with_row(line)
  local row = line:match(":(%d+):")
  if not row then
    return
  end

  local row_pattern = (":%s:"):format(row)
  local row_index = line:find(row_pattern)

  local path = line:sub(1, row_index - 1)
  local matched_line = line:sub(row_index + #row_pattern)
  return path, tonumber(row), matched_line
end

function M.find_root(pattern)
  local file = vim.api.nvim_get_runtime_file("lua/" .. pattern, false)[1]
  if file == nil then
    return nil, "project root directory not found by pattern: " .. pattern
  end
  return vim.split(M.adjust_sep(file), "/lua/", { plain = true })[1], nil
end

if vim.uv.os_uname().version:match("Windows") then
  function M.adjust_sep(path)
    return path:gsub("\\", "/")
  end

  function M.home()
    return os.getenv("USERPROFILE")
  end

  M.env_separator = ";"
else
  function M.adjust_sep(path)
    return path
  end

  function M.home()
    return os.getenv("HOME")
  end

  M.env_separator = ":"
end

-- for app

function M.user_data_path(file_name)
  return vim.fn.stdpath("data") .. "/thetto.nvim/" .. file_name
end

return M
