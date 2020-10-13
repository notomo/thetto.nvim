local vim = vim

local M = {}

local Highlighter = {}
Highlighter.__index = Highlighter

function Highlighter.add(self, hl_group, row, start_col, end_col)
  vim.api.nvim_buf_add_highlight(self.bufnr, self.ns, hl_group, row, start_col, end_col)
end

function Highlighter.set_virtual_text(self, row, chunks)
  vim.api.nvim_buf_set_virtual_text(self.bufnr, self.ns, row, chunks, {})
end

function Highlighter.filter(self, hl_group, elements, condition)
  for i, e in ipairs(elements) do
    if condition(e) then
      self:add(hl_group, i - 1, 0, -1)
    end
  end
end

local Factory = {}
Factory.__index = Factory

function Factory.create(self, bufnr)
  local highlighter = {bufnr = bufnr, ns = self.ns}
  return setmetatable(highlighter, Highlighter)
end

function Factory.reset(self, bufnr)
  local highlighter = self:create(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, self.ns, 0, -1)
  return highlighter
end

M.new_factory = function(key)
  local ns = vim.api.nvim_create_namespace(key)
  local factory = {ns = ns}
  return setmetatable(factory, Factory)
end

return M
