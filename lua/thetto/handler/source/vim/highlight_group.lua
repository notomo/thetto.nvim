local vim = vim

local M = {}

local colored = "xxx"

local color_attributes = {
  {"ctermfg", "fg", "cterm"},
  {"ctermbg", "bg", "cterm"},
  {"guifg", "fg", "gui"},
  {"guibg", "bg", "gui"},
  {"font", "font", "gui"},
  {"guisp", "sp", "gui"},
}

local attributes = {
  "bold",
  "italic",
  "reverse",
  "standout",
  "underline",
  "undercurl",
  "strikethrough",
}

function M.collect()
  local items = {}
  local names = vim.fn.getcompletion("*", "highlight")
  for _, name in ipairs(names) do
    local id = vim.api.nvim_get_hl_id_by_name(name)
    local origin_id = vim.fn.synIDtrans(id)

    local desc
    if id == origin_id then
      local factors = {colored, name}
      for _, attr in ipairs(color_attributes) do
        local key, what, mode = unpack(attr)
        local value = vim.fn.synIDattr(origin_id, what, mode)
        if value ~= "" then
          table.insert(factors, key .. "=" .. value)
        end
      end

      do
        local values = vim.tbl_filter(function(what)
          return vim.fn.synIDattr(origin_id, what, "gui") == "1"
        end, attributes)
        local value = table.concat(values, ",")
        if value ~= "" then
          table.insert(factors, "gui=" .. value)
        end
      end
      do
        local values = vim.tbl_filter(function(what)
          return vim.fn.synIDattr(origin_id, what, "cterm") == "1"
        end, attributes)
        local value = table.concat(values, ",")
        if value ~= "" then
          table.insert(factors, "cterm=" .. value)
        end
      end

      local blend = vim.api.nvim_get_hl_by_name(name, false).blend
      if blend then
        table.insert(factors, "blend=" .. tostring(blend))
      end

      if #factors == 2 then
        table.insert(factors, "cleared")
      end
      desc = table.concat(factors, " ")
    else
      local link = vim.fn.synIDattr(origin_id, "name")
      desc = ("%s %s links to %s"):format(colored, name, link)
    end

    table.insert(items, {desc = desc, value = name, column_offsets = {value = #colored + 1}})
  end
  return items
end

function M.highlight(self, bufnr, first_line, items)
  local highlighter = self.highlights:create(bufnr)
  local end_col = #colored
  for i, item in ipairs(items) do
    highlighter:add(item.value, first_line + i - 1, 0, end_col)
  end
end

M.kind_name = "vim/highlight_group"

return M
