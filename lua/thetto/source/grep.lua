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

M.make = function(list, opts)
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
      table.insert(items, {value = matched_line, path = path, row = row})
      ::continue::
    end
    vim.list_extend(all_items, items)
    list.set(all_items)
  end

  local paths = vim.fn.fnamemodify(".", ":p")
  local cmd = vim.list_extend({M.command}, M.opts)
  vim.list_extend(cmd, {M.recursive_opt, M.pattern_opt, pattern, M.separator, paths})
  local job = jobs.new(cmd, {
    on_stdout = function(_, _, data)
      if data == nil then
        return
      end
      all_data = all_data .. data
    end,
    on_exit = update,
    on_interval = update,
  })

  return {}, job
end

M.kind_name = "file/position"

return M
