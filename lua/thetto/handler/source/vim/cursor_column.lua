local M = {}

local function char_width(ch, vcol, tabstop)
  if ch == "\t" then
    return tabstop - ((vcol - 1) % tabstop)
  end
  return vim.fn.strdisplaywidth(ch)
end

local function char_len(byte)
  if byte >= 0xF0 then
    return 4
  elseif byte >= 0xE0 then
    return 3
  elseif byte >= 0xC0 then
    return 2
  end
  return 1
end

local function virtcol_of_byte(line, byte_col, tabstop)
  local vcol = 1
  local i = 0
  while i < byte_col and i < #line do
    local len = char_len(line:byte(i + 1))
    local ch = line:sub(i + 1, i + len)
    vcol = vcol + char_width(ch, vcol, tabstop)
    i = i + len
  end
  return vcol
end

local function keep_edges(items)
  local result = {}
  local i = 1
  while i <= #items do
    local j = i
    while j < #items and items[j + 1].row == items[j].row + 1 do
      j = j + 1
    end
    table.insert(result, items[i])
    if j > i then
      table.insert(result, items[j])
    end
    i = j + 1
  end
  return result
end

local function has_nonspace_at(line, target_vcol, tabstop)
  local vcol = 1
  local i = 1
  while i <= #line do
    local len = char_len(line:byte(i))
    local ch = line:sub(i, i + len - 1)
    local width = char_width(ch, vcol, tabstop)
    if vcol <= target_vcol and target_vcol < vcol + width then
      return not ch:match("^%s+$")
    end
    vcol = vcol + width
    if vcol > target_vcol then
      return false
    end
    i = i + len
  end
  return false
end

function M.collect(source_ctx)
  local bufnr = source_ctx.bufnr
  local window_id = source_ctx.window_id
  local tabstop = vim.bo[bufnr].tabstop

  local cursor = vim.api.nvim_win_get_cursor(window_id)
  local cursor_row = cursor[1]
  local cursor_byte_col = cursor[2]
  local cursor_line = vim.api.nvim_buf_get_lines(bufnr, cursor_row - 1, cursor_row, true)[1] or ""
  local target_vcol = virtcol_of_byte(cursor_line, cursor_byte_col, tabstop)

  local kind_name
  local path = vim.api.nvim_buf_get_name(bufnr) ---@type string|nil
  if not vim.bo[bufnr].modified and vim.fn.filereadable(tostring(path)) == 1 then
    kind_name = "file"
  else
    path = nil
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
  local items = vim
    .iter(lines)
    :enumerate()
    :filter(function(_, line)
      return has_nonspace_at(line, target_vcol, tabstop)
    end)
    :map(function(i, line)
      return {
        value = line,
        row = i,
        column = cursor_byte_col,
        kind_name = kind_name,
        path = path,
        bufnr = bufnr,
      }
    end)
    :totable()
  return keep_edges(items)
end

M.kind_name = "vim/position"

return M
