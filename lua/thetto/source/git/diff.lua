local M = {}

local to_hunks = function(lines)
  local hunks = {}

  local hunk
  local searching = false
  for i, line in ipairs(lines) do
    if vim.startswith(line, "@@") then
      local first_row = line:match("@@ %-%d+,%d+ %+(%d+),")
      hunk = {desc = line, _first_row = first_row, _start = i + 1, minus = 0}
      searching = true
    elseif searching and vim.startswith(line, "+") then
      local row_diff = i - hunk._start - hunk.minus
      local row = hunk._first_row + row_diff
      table.insert(hunks, {row = row, desc = hunk.desc})
      searching = false
    elseif searching and vim.startswith(line, "-") then
      hunk.minus = hunk.minus + 1
    elseif vim.startswith(line, " ") then
      searching = true
    end
  end

  return hunks
end

M.collect = function(self, opts)
  local file_path = vim.fn.expand("%:p")
  if not self.filelib.readable(file_path) then
    return {}, nil
  end

  local git_root = self.filelib.find_upward_dir(".git")
  if git_root == nil then
    return {}, nil
  end

  local name = self.pathlib.to_relative(file_path, git_root)

  local cmd = {"git", "diff", "--no-color", name}
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local items = {}
      local hunks = to_hunks(job_self:get_stdout())
      for _, hunk in ipairs(hunks) do
        table.insert(items, {value = hunk.desc, row = hunk.row, path = file_path})
      end
      self.append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = opts.cwd,
  })

  return {}, job
end

M.kind_name = "file"

return M
