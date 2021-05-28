local vim = vim

local M = {}

local Highlighter = {}
Highlighter.__index = Highlighter

-- HACK
function Highlighter.add_normal(self, hl_group, row, start_col, end_col)
  vim.api.nvim_buf_add_highlight(self.bufnr, self.ns, hl_group, row, start_col, end_col)
end

function Highlighter.add(self, hl_group, row, start_col, end_col)
  local end_line
  if end_col == -1 then
    end_line = row + 1
    end_col = nil
  end
  vim.api.nvim_buf_set_extmark(self.bufnr, self.ns, row, start_col, {
    hl_group = hl_group,
    end_line = end_line,
    end_col = end_col,
    ephemeral = true,
  })
end

function Highlighter.set_virtual_text(self, row, chunks, opts)
  opts = opts or {}
  opts.virt_text = chunks
  vim.api.nvim_buf_set_extmark(self.bufnr, self.ns, row, 0, opts)
end

function Highlighter.add_line(self, hl_group, row)
  vim.api.nvim_buf_set_extmark(self.bufnr, self.ns, row, 0, {
    hl_group = hl_group,
    end_line = row + 1,
    ephemeral = true,
  })
end

function Highlighter.filter(self, hl_group, row, elements, condition)
  for i, e in ipairs(elements) do
    if condition(e) then
      self:add_line(hl_group, row + i - 1)
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

function M.new_factory(key)
  local ns = vim.api.nvim_create_namespace(key)
  local factory = {ns = ns}
  return setmetatable(factory, Factory)
end

return M
