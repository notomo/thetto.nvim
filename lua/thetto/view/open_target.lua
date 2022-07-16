local filelib = require("thetto.lib.file")

local M = {}

local new_buffer = function(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].bufhidden = "wipe"
  return bufnr
end

local highlight = function(hl_factory, bufnr, row, range)
  if not row then
    return
  end

  local highlighter = hl_factory:create(bufnr)
  range = range or { s = { column = 0 }, e = { column = -1 } }
  highlighter:add_normal("ThettoPreview", row - 1, range.s.column, range.e.column)
  if vim.fn.getbufline(bufnr, row)[1] == "" then
    highlighter:set_virtual_text(row - 1, { { " ", "ThettoPreview" } }, { virt_text_pos = "overlay" })
  end
end

local set_cursor = function(window_id, row, range, width)
  if not row then
    return
  end
  range = range or { s = { column = 0 }, e = { column = -1 } }
  vim.api.nvim_win_set_cursor(window_id, { row, range.s.column })
  if range.e.column <= width then
    return
  end
  vim.api.nvim_win_call(window_id, function()
    vim.cmd([[normal! zs]]) -- HACK
  end)
end

local set_filetype = function(bufnr, hint)
  local filetype, on_detect = vim.filetype.match(hint)
  if filetype then
    on_detect = on_detect or function() end
    vim.bo[bufnr].filetype = filetype
    on_detect(bufnr)
  end
end

function M.new(target, width, height)
  local bufnr
  if target.bufnr then
    bufnr = M._buffer(target.bufnr, height, target.row)
  elseif target.raw_bufnr then
    bufnr = target.raw_bufnr
  elseif target.path then
    bufnr = M._path(target.path, height, target.row)
  else
    bufnr = new_buffer(target.lines or {})
  end
  return bufnr,
    function(hl_factory, window_id)
      set_cursor(window_id, target.row, target.range, width)
      highlight(hl_factory, bufnr, target.row, target.range)
    end
end

function M._buffer(source_bufnr, height, row)
  if not vim.api.nvim_buf_is_valid(source_bufnr) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(source_bufnr, 0, (row or 0) + height - 1, false)
  local path = vim.api.nvim_buf_get_name(source_bufnr)
  local bufnr = new_buffer(lines)

  set_filetype(bufnr, { buf = bufnr, filename = path })

  return bufnr
end

function M._path(path, height, row)
  local lines = filelib.read_lines(path, 1, (row or 0) + height)
  local bufnr = new_buffer(lines)

  set_filetype(bufnr, { buf = bufnr, filename = path })

  return bufnr
end

return M
