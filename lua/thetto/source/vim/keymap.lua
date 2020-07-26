local M = {}

local modes = "nvoicsxlt"

M.collect = function(_)
  local keymaps = {}
  for _, mode in ipairs(vim.split(modes, "")) do
    vim.list_extend(keymaps, vim.api.nvim_get_keymap(mode))
    vim.list_extend(keymaps, vim.api.nvim_buf_get_keymap(0, mode))
  end

  local items = {}
  for _, keymap in ipairs(keymaps) do
    local factors = {}

    local mode = keymap.mode
    if mode == " " then
      mode = "nov"
    elseif mode == "!" then
      mode = "ic"
    end
    table.insert(factors, mode)

    if keymap.noremap == 1 then
      table.insert(factors, "noremap")
    else
      table.insert(factors, "map")
    end
    if keymap.silent == 1 then
      table.insert(factors, "<silent>")
    end
    if keymap.nowait == 1 then
      table.insert(factors, "<nowait>")
    end
    if keymap.buffer ~= 0 then
      table.insert(factors, "<buffer>")
    end
    if keymap.expr == 1 then
      table.insert(factors, "<expr>")
    end

    local lhs = keymap.lhs:gsub(" ", "<Space>")
    table.insert(factors, lhs)

    local rhs = keymap.rhs
    if rhs == "" then
      rhs = "<Nop>"
    end
    table.insert(factors, rhs)

    local value = table.concat(factors, " ")
    table.insert(items, {
      value = value,
      keymap = {mode = mode, lhs = lhs, rhs = rhs, row = keymap.lnum},
    })
  end
  return items
end

M.kind_name = "vim/keymap"

return M
