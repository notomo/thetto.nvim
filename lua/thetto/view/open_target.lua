local filelib = require("thetto.lib.file")

local M = {}

local get_position = function(height, row)
  local half_height = math.floor(height / 2)
  if row ~= nil and row > half_height then
    return {
      top_row = row - half_height + 1,
      row = half_height,
    }
  end
  return {
    top_row = 1,
    row = row,
  }
end

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

function M.new(target, height)
  if target.bufnr then
    return M._buffer(target.bufnr, height, target.row, target.range)
  elseif target.raw_bufnr then
    return M._raw_buffer(target.raw_bufnr, target.row, target.range)
  elseif target.path then
    return M._path(target.path, height, target.row, target.range)
  end
  return M._lines(target.lines or {}, height, target.row, target.range)
end

function M._buffer(source_bufnr, height, row, range)
  if not vim.api.nvim_buf_is_valid(source_bufnr) then
    return
  end

  local position = get_position(height, row)

  local lines = vim.api.nvim_buf_get_lines(source_bufnr, position.top_row - 1, position.top_row + height - 1, false)
  local path = vim.api.nvim_buf_get_name(source_bufnr)
  local bufnr = new_buffer(lines)

  vim.filetype.match(path, bufnr)

  return bufnr, function(hl_factory)
    highlight(hl_factory, bufnr, position.row, range)
  end
end

function M._raw_buffer(bufnr, row, range)
  return bufnr,
    function(hl_factory, window_id)
      if row then
        vim.api.nvim_win_set_cursor(window_id, { row, 0 })
      end
      highlight(hl_factory, bufnr, row, range)
    end
end

function M._lines(lines, height, row, range)
  local position = get_position(height, row)
  local bufnr = new_buffer(lines)
  return bufnr, function(hl_factory)
    highlight(hl_factory, bufnr, position.row, range)
  end
end

function M._path(path, height, row, range)
  local position = get_position(height, row)
  local lines = filelib.read_lines(path, position.top_row, position.top_row + height)
  local bufnr = new_buffer(lines)

  vim.filetype.match(path, bufnr)

  return bufnr, function(hl_factory)
    highlight(hl_factory, bufnr, position.row, range)
  end
end

return M
