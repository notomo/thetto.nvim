local filelib = require("thetto.lib.file")

local M = {}

--- @async
function M.action_add()
  local git_root, err = filelib.find_git_root()
  if err then
    return err
  end

  local remote_name = vim.trim(require("thetto.util.input").await({
    prompt = "Add remote: ",
    default = "upstream",
  }) or "")
  if remote_name == "" then
    return require("thetto.lib.message").info("invalid name to add remote: " .. tostring(remote_name))
  end

  local url = vim.trim(require("thetto.util.input").await({
    prompt = "Remote url: ",
    default = "https://github.com/user/repo.git",
  }) or "")
  if url == "" then
    return require("thetto.lib.message").info("invalid url to add remote: " .. tostring(url))
  end

  return require("thetto.util.job").await({ "git", "remote", "add", remote_name, url }, { cwd = git_root })
end

return M
