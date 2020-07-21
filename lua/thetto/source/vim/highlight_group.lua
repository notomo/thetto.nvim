local highlight = require("thetto/highlight")

local M = {}

local colored = "xxx"

M.make = function()
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
      desc = ("xxx %s links to %s"):format(name, link)
    end

    table.insert(items, {desc = desc, value = name})
  end
  return items
end

M.highlight = function(bufnr, items)
  local ns = highlight.reset(bufnr)
  local end_col = #colored
  for i, item in ipairs(items) do
    vim.api.nvim_buf_add_highlight(bufnr, ns, item.value, i - 1, 0, end_col)
  end
end

M.kind_name = "word"

return M
