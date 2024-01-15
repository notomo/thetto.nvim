local M = {}

function M.action_list_action_step(items)
  for _, item in ipairs(items) do
    local source = require("thetto2.util.source").by_name("github/action/step", {
      opts = { owner = item.job.owner, repo = item.job.repo, job_id = item.job.id },
    })
    return require("thetto2").start(source)
  end
end

function M.action_download_log(items)
  local item = items[1]
  if not item then
    return nil
  end

  local cmd = {
    "gh",
    "api",
    ("/repos/:owner/:repo/actions/runs/%s/logs"):format(item.run.id),
  }
  return require("thetto2.util.job")
    .promise(cmd, {
      on_exit = function() end,
    })
    :next(function(output)
      local file_path = vim.fn.tempname()
      local f = io.open(file_path, "w")
      f:write(output)
      f:close()

      local output_dir = vim.fn.stdpath("cache") .. "/thetto/github_action_log/" .. item.run.id
      vim.fn.mkdir(output_dir, "p")

      return require("thetto2.util.job").promise({ "unzip", "-o", file_path, "-d", output_dir })
    end)
end

M.action_list_children = M.action_list_action_step

return require("thetto2.core.kind").extend(M, "url")
