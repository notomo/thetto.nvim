local filelib = require("thetto.lib.file")

local M = {}

local to_hunks = function(lines)
  local hunks = {}

  local hunk, path
  local searching_in_hunk = false
  for i, line in ipairs(lines) do
    if vim.startswith(line, "--- a/") then
      path = line:sub(#"--- a/" + 1)
      searching_in_hunk = false
    elseif vim.startswith(line, "@@") then
      local first_row = line:match("@@ %-%d+,%d+ %+(%d+),")
      hunk = { desc = line, _first_row = first_row, _start = i + 1, minus = 0, path = path }
      searching_in_hunk = true
    elseif searching_in_hunk and vim.startswith(line, "+") then
      local row_diff = i - hunk._start - hunk.minus
      local row = hunk._first_row + row_diff
      local desc = ("%s:%d  %s"):format(hunk.path, row, hunk.desc)
      table.insert(hunks, { row = row, desc = desc, path = hunk.path })
      searching_in_hunk = false
    elseif searching_in_hunk and vim.startswith(line, "-") then
      hunk.minus = hunk.minus + 1
      local row_diff = i - hunk._start - hunk.minus
      local row = hunk._first_row + row_diff
      local desc = ("%s:%d  %s"):format(hunk.path, row, hunk.desc)
      table.insert(hunks, { row = row, desc = desc, path = hunk.path })
    elseif vim.startswith(line, " ") then
      searching_in_hunk = true
    end
  end

  local merged = { hunks[1] }
  for item in vim.iter(hunks):skip(1) do
    local last = merged[#merged]
    if last.path ~= item.path or last.row < item.row - 1 then
      table.insert(merged, item)
    end
  end

  return merged
end

M.opts = { expr = nil }

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root(source_ctx.cwd)
  if err ~= nil then
    return err
  end

  local path
  if source_ctx.opts.expr ~= nil then
    path = vim.fn.expand(source_ctx.opts.expr)
  end

  if path == "" then
    return {}
  end

  local cmd = { "git", "--no-pager", "diff", "--no-color", path }
  return require("thetto.util.job").run(cmd, source_ctx, function(hunk)
    return {
      value = hunk.desc,
      row = hunk.row,
      path = path or vim.fs.joinpath(git_root, hunk.path),
    }
  end, {
    cwd = git_root,
    to_outputs = function(output)
      local lines = require("thetto.util.job.parse").output(output)
      return to_hunks(lines)
    end,
  })
end

M.kind_name = "file"

M.cwd = require("thetto.util.cwd").project()

return M
