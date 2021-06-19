local M = {}

local to_hunks = function(lines)
  local hunks = {}

  local hunk, path
  local searching_in_hunk = false
  for i, line in ipairs(lines) do
    if vim.startswith(line, "--- a/") then
      path = line:sub(#("--- a/") + 1)
      searching_in_hunk = false
    elseif vim.startswith(line, "@@") then
      local first_row = line:match("@@ %-%d+,%d+ %+(%d+),")
      hunk = {desc = line, _first_row = first_row, _start = i + 1, minus = 0, path = path}
      searching_in_hunk = true
    elseif searching_in_hunk and vim.startswith(line, "+") then
      local row_diff = i - hunk._start - hunk.minus
      local row = hunk._first_row + row_diff
      local desc = ("%s:%d  %s"):format(hunk.path, row, hunk.desc)
      table.insert(hunks, {row = row, desc = desc, path = hunk.path})
      searching_in_hunk = false
    elseif searching_in_hunk and vim.startswith(line, "-") then
      hunk.minus = hunk.minus + 1
    elseif vim.startswith(line, " ") then
      searching_in_hunk = true
    end
  end

  return hunks
end

M.opts = {expr = nil}

function M.collect(self, opts)
  local git_root, err = self.filelib.find_git_root()
  if err ~= nil then
    return {}, nil, err
  end

  local path
  if self.opts.expr ~= nil then
    path = vim.fn.expand(self.opts.expr)
  end

  local cmd = {"git", "--no-pager", "diff", "--no-color", path}
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local items = {}
      local hunks = to_hunks(job_self:get_stdout())
      for _, hunk in ipairs(hunks) do
        table.insert(items, {
          value = hunk.desc,
          row = hunk.row,
          path = path or self.pathlib.join(git_root, hunk.path),
        })
      end
      self:append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = opts.cwd,
  })

  return {}, job
end

M.kind_name = "file"

return M
