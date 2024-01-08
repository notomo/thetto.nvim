local filelib = require("thetto2.lib.file")

local M = {}

function M.action_add()
  local git_root, err = filelib.find_git_root()
  if err then
    return nil, err
  end

  local remote_name
  return require("thetto2.util.input")
    .promise({
      prompt = "Add remote: ",
      default = "upstream",
    })
    :next(function(name)
      name = vim.trim(name)
      if not name or name == "" then
        return require("thetto2.vendor.misclib.message").info("invalid name to add remote: " .. tostring(name))
      end
      remote_name = name
      return require("thetto2.util.input").promise({
        prompt = "Remote url: ",
        default = "https://github.com/user/repo.git",
      })
    end)
    :next(function(url)
      url = vim.trim(url)
      if not url or url == "" then
        return require("thetto2.vendor.misclib.message").info("invalid url to add remote: " .. tostring(url))
      end
      return require("thetto2.util.job").promise({ "git", "remote", "add", remote_name, url }, { cwd = git_root })
    end)
end

return M
