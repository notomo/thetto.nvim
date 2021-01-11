local M = {}

M.opts = {all = false}

M.collect = function(self, opts)
  local _, err = self.filelib.find_git_root()
  if err ~= nil then
    return {}, nil, err
  end

  local cmd = {"git", "branch", "--format", "%(refname:short)"}
  if self.opts.all then
    table.insert(cmd, "--all")
  end

  local current_branch = nil
  local get_current_job = self.jobs.new({"git", "rev-parse", "--abbrev-ref", "HEAD"}, {
    on_exit = function(job_self)
      current_branch = job_self:get_stdout()[1]
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = opts.cwd,
  })
  local joberr = get_current_job:start()
  if joberr ~= nil then
    return nil, nil, joberr
  end
  get_current_job:wait(1000)

  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local items = {}
      for _, output in ipairs(job_self:get_stdout()) do
        local is_current_branch = output == current_branch
        table.insert(items, {value = output, is_current_branch = is_current_branch})
      end
      self.append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = opts.cwd,
  })

  return {}, job
end

vim.cmd("highlight default link ThettoGitActiveBranch Type")

M.highlight = function(self, bufnr, items)
  local highlighter = self.highlights:reset(bufnr)
  for i, item in ipairs(items) do
    if item.is_current_branch then
      highlighter:add("ThettoGitActiveBranch", i - 1, 0, -1)
    end
  end
end

M.kind_name = "git/branch"

return M
