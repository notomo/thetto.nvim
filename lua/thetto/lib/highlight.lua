local vim = vim

local M = {}

local Highlighter = {}
Highlighter.__index = Highlighter

function Highlighter.new(ns, bufnr)
  vim.validate({ns = {ns, "number"}, bufnr = {bufnr, "number"}})
  local tbl = {_ns = ns, _bufnr = bufnr}
  return setmetatable(tbl, Highlighter)
end

-- HACK
function Highlighter.add_normal(self, hl_group, row, start_col, end_col)
  vim.api.nvim_buf_add_highlight(self._bufnr, self._ns, hl_group, row, start_col, end_col)
end

function Highlighter.add(self, hl_group, row, start_col, end_col)
  local end_line
  if end_col == -1 then
    end_line = row + 1
    end_col = nil
  end
  vim.api.nvim_buf_set_extmark(self._bufnr, self._ns, row, start_col, {
    hl_group = hl_group,
    end_line = end_line,
    end_col = end_col,
    ephemeral = true,
  })
end

function Highlighter.set_virtual_text(self, row, chunks, opts)
  opts = opts or {}
  opts.virt_text = chunks
  vim.api.nvim_buf_set_extmark(self._bufnr, self._ns, row, 0, opts)
end

function Highlighter.add_line(self, hl_group, row)
  vim.api.nvim_buf_set_extmark(self._bufnr, self._ns, row, 0, {
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

local HighlighterFactory = {}
HighlighterFactory.__index = HighlighterFactory
M.HighlighterFactory = HighlighterFactory

function HighlighterFactory.new(key, bufnr)
  vim.validate({key = {key, "string"}, bufnr = {bufnr, "number", true}})
  local ns = vim.api.nvim_create_namespace(key)
  local factory = {_ns = ns, _bufnr = bufnr}
  return setmetatable(factory, HighlighterFactory)
end

function HighlighterFactory.create(self, bufnr)
  vim.validate({bufnr = {bufnr, "number", true}})
  bufnr = bufnr or self._bufnr
  return Highlighter.new(self._ns, bufnr)
end

function HighlighterFactory.reset(self, bufnr)
  vim.validate({bufnr = {bufnr, "number", true}})
  bufnr = bufnr or self._bufnr
  local highlighter = self:create(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, self._ns, 0, -1)
  return highlighter
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

local Ensured = {}
Ensured.__index = Ensured
M.Ensured = Ensured

function Ensured.new(hl_group, define_hl)
  local tbl = {_hl_group = hl_group, _define_hl = define_hl}
  return setmetatable(tbl, Ensured)
end

-- NOTE: returns valid hl_group even cleared
function Ensured.__call(self)
  local name = vim.fn.getcompletion(self._hl_group, "highlight")[1]
  if name then
    return self._hl_group
  end
  self._define_hl(self._hl_group)
  return self._hl_group
end

return M
