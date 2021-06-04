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

function M.default(name, attributes)
  local parts = {}
  for attr_name, v in pairs(attributes) do
    local value = v
    if type(v) == "table" then
      local hl_group, default = unpack(v)
      value = M.get_attribute(hl_group, attr_name) or default
    elseif type(v) == "string" then
      value = M.get_attribute(v, attr_name)
    end
    table.insert(parts, ("%s=%s"):format(attr_name, value))
  end

  local cmd = ("highlight default %s %s"):format(name, table.concat(parts, " "))
  vim.cmd(cmd)
  return name
end

local ATTRIBUTES = {
  ctermfg = {"fg", "cterm"},
  guifg = {"fg", "gui"},
  ctermbg = {"bg", "cterm"},
  guibg = {"bg", "gui"},
}
function M.get_attribute(hl_group, name)
  local hl_id = vim.api.nvim_get_hl_id_by_name(hl_group)
  local value = vim.fn.synIDattr(hl_id, unpack(ATTRIBUTES[name]))
  if value ~= "" then
    return value
  end
  return nil
end

return M
