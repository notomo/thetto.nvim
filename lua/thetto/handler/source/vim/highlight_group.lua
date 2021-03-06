local vim = vim

local M = {}

local colored = "xxx"

function M.collect()
  local items = {}
  local names = vim.fn.getcompletion("*", "highlight")
  for _, name in ipairs(names) do
    local id = vim.api.nvim_get_hl_id_by_name(name)
    local origin_id = vim.fn.synIDtrans(id)

    local desc
    if id == origin_id then
      local cterm_fg = vim.fn.synIDattr(origin_id, "fg", "cterm")
      local cterm_bg = vim.fn.synIDattr(origin_id, "bg", "cterm")
      local gui_fg = vim.fn.synIDattr(origin_id, "fg", "gui")
      local gui_bg = vim.fn.synIDattr(origin_id, "bg", "gui")
      local factors = {colored, name}
      if cterm_fg ~= "" then
        table.insert(factors, "ctermfg=" .. cterm_fg)
      end
      if cterm_bg ~= "" then
        table.insert(factors, "ctermbg=" .. cterm_bg)
      end
      if gui_fg ~= "" then
        table.insert(factors, "guifg=" .. gui_fg)
      end
      if gui_bg ~= "" then
        table.insert(factors, "guibg=" .. gui_bg)
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
