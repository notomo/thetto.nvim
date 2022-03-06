local listlib = require("thetto.lib.list")
local filelib = require("thetto.lib.file")
local vim = vim

local M = {}

M.limit = 500
M.ignore_pattern = "^$"

function M.start(self)
  local paths = filelib.read_lines(self.file_path, 0, self.limit)
  self.persist.paths = vim.tbl_filter(self:validator(), paths)

  vim.api.nvim_create_augroup(self.augroup_name, {})
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = self.augroup_name,
    pattern = { "*" },
    callback = function()
      local bufnr = tonumber(vim.fn.expand("<abuf>"))
      self:add(bufnr)
    end,
  })
  vim.api.nvim_create_autocmd({ "QuitPre" }, {
    group = self.augroup_name,
    pattern = { "*" },
    callback = function()
      self:save()
    end,
  })
end

function M.data(self)
  return vim.fn.reverse(self.persist.paths)
end

function M.validator(self)
  local regex = vim.regex(self.ignore_pattern)
  return function(path)
    return not regex:match_str(path) and filelib.readable(path)
  end
end

function M.is_valid(self, path)
  return self:validator()(path)
end

function M.add(self, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    return
  end

  if not self:is_valid(path) then
    return
  end

  local removed = listlib.remove(self.persist.paths, path)
  if not removed and #self.persist.paths > self.limit then
    table.remove(self.persist.paths, 1)
  end

  table.insert(self.persist.paths, path)
end

function M.save(self)
  filelib.write_lines(self.file_path, self.persist.paths)
end

return M
