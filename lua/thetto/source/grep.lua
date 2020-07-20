local jobs = require "thetto/job"

local M = {}

local parse_line = function(line)
  local path_row = line:match(".*:%d+:")
  if not path_row then
    return
  end
  local path, row = unpack(vim.split(path_row, ":", true))
  local matched_line = line:sub(#path_row + 1)
  return path, tonumber(row), matched_line
end

M.command = "grep"
M.pattern_opt = "-e"
M.opts = {"-inH"}
M.recursive_opt = "-r"
M.separator = "--"

M.make = function(opts, list)
  local pattern = opts.input or vim.fn.input("Pattern: ")
  if pattern == "" then
    return {}, nil
  end

  local all_items = {}
  local all_data = ""
  local update = function(self)
    local items = {}
    local outputs = self.parse_output(all_data)
    all_data = ""
    for _, output in ipairs(outputs) do
      local path, row, matched_line = parse_line(output)
      if path == nil then
        goto continue
      end
      local relative_path = path:gsub("^" .. opts.cwd .. "/", "")
      local desc = ("%s:%d %s"):format(relative_path, row, matched_line)
      table.insert(items, {desc = desc, value = matched_line, path = path, row = row})
      ::continue::
    end
    vim.list_extend(all_items, items)
    list.set(all_items)
  end

  local paths = opts.cwd
  local cmd = vim.list_extend({M.command}, M.opts)
  for _, x in ipairs({M.recursive_opt, M.pattern_opt, pattern, M.separator, paths}) do
    if x == "" then
      goto continue
    end
    table.insert(cmd, x)
    ::continue::
  end
  local job = jobs.new(cmd, {
    on_stdout = function(_, _, data)
      if data == nil then
        return
      end
      all_data = all_data .. data
    end,
    on_exit = update,
    on_interval = update,
    cwd = opts.cwd,
  })

  return {}, job
end

M.kind_name = "file/position"

return M
