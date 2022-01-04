local M = {}

function M.collect(self, opts)
  local file_path = vim.api.nvim_buf_get_name(0)
  if not self.filelib.readable(file_path) then
    return {}, nil
  end

  local cmd = { "gron", "--monochrome", file_path }
  local job = self.jobs.new(cmd, {
    on_exit = function(job_self)
      local items = {}
      for _, output in ipairs(job_self:get_stdout()) do
        local pattern = M._to_pattern(output)
        table.insert(items, { value = output, path = file_path, pattern = pattern })
      end
      self:append(items)
    end,
    on_stderr = self.jobs.print_stderr,
    cwd = opts.cwd,
  })

  return {}, job
end

M.indent = 2

-- NOTICE: This does not generate unique pattern in file.
function M._to_pattern(text)
  local e = text:find(" = ")

  local key_text = text:sub(#"json" + 1, e - 1)
  local tmp_key1, index_count = key_text:gsub("%[%d+%]", "")
  -- NOTICE: not supported quoted key
  local tmp_key2, dot_count1 = tmp_key1:gsub("[^.]+%.", "")
  local key, dot_count2 = tmp_key2:gsub("%.", "")
  local depth = index_count + dot_count1 + dot_count2

  local value = text:sub(e + #" = ", -2)
  if value == "[]" then
    value = "["
  elseif value == "{}" then
    value = "\\{"
    if key_text:find("%[%d+%]$") then
      -- NOTICE: not supported nested array element
      depth = depth - 1
      value = "["
    end
  end

  local space = (" "):rep(depth * M.indent)
  if key ~= "" then
    return ([[\v^%s"%s": %s,?$]]):format(space, key, value)
  end
  return ([[\v^%s%s,?$]]):format(space, value)
end

M.kind_name = "file"

return M
