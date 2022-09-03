local filelib = require("thetto.lib.file")

local M = {}

function M.collect(source_ctx)
  local file_path = vim.api.nvim_buf_get_name(0)
  if not filelib.readable(file_path) then
    return {}, nil
  end

  local cmd = { "gron", "--monochrome", file_path }
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local pattern = M._to_pattern(output)
    return {
      value = output,
      path = file_path,
      pattern = pattern,
    }
  end)
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
