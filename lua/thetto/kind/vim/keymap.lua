local M = {}

M.action_execute = function(_, items)
  for _, item in ipairs(items) do
    if not item.keymap.mode:find("n") then
      goto continue
    end

    local lhs = vim.api.nvim_replace_termcodes(item.keymap.lhs, true, false, true)
    vim.api.nvim_feedkeys(lhs, "mx", true)
    ::continue::
  end
end

local to_files = function(items)
  local files = {}
  for _, item in ipairs(items) do
    local result = vim.api.nvim_exec("verbose map " .. item.keymap.lhs, true)
    local outputs = vim.split(result, "\n", true)
    for _, output in ipairs(outputs) do
      local path = output:match("^%s+Last%s+set%s+from%s+(%S+)")
      if path ~= nil then
        table.insert(files, {path = path, row = item.keymap.row})
        break
      end
    end
  end
  return files
end

local file_kind = require("thetto/kind/file")

M.action_open = function(self, items)
  file_kind.action_open(self, to_files(items))
end

M.action_tab_open = function(self, items)
  file_kind.action_tab_open(self, to_files(items))
end

M.action_vsplit_open = function(self, items)
  file_kind.action_vsplit_open(self, to_files(items))
end

M.default_action = "execute"

return M
