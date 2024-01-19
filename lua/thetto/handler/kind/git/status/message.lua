local M = {}

M.opts = {}

local git_status = require("thetto.handler.kind.git.status")
M.opts.commit = git_status.opts.commit
M.action_commit = git_status.action_commit
M.action_commit_amend = git_status.action_commit_amend
M.action_commit_empty = git_status.action_commit_empty
M.action_toggle_stage = function()
  error("This action should be skipped")
end
M.action_discard = function()
  error("This action should be skipped")
end

return M
