local filelib = require("thetto2.lib.file")
local hl_groups = require("thetto2.handler.consumer.ui.highlight_group")

local M = {}

local new_buffer = function(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].bufhidden = "wipe"
  return bufnr
end

local highlight = function(decorator_factory, bufnr, row, end_row, column, end_column, height)
  if not row then
    return
  end

  local decorator = decorator_factory:create(bufnr)
  if column then
    local row_limit = row + height - 1
    end_row = end_row and (end_row > row_limit) and row_limit or end_row
    decorator:highlight_range(hl_groups.ThettoUiPreview, row - 1, end_row, column, end_column)
  else
    decorator:highlight(hl_groups.ThettoUiPreview, row - 1, 0, -1)
  end
  if vim.fn.getbufline(bufnr, row)[1] == "" then
    decorator:add_virtual_text(row - 1, 0, { { " ", hl_groups.ThettoUiPreview } }, { virt_text_pos = "overlay" })
  end
end

local set_cursor = function(window_id, row, column, end_column, width)
  if not row then
    return
  end
  column = column or 0
  end_column = end_column or -1
  vim.api.nvim_win_set_cursor(window_id, { row, column })
  if end_column <= width then
    return
  end
  vim.api.nvim_win_call(window_id, function()
    vim.cmd.normal({ args = { "zs" }, bang = true }) -- HACK
  end)
end

local set_filetype = function(bufnr, hint)
  local filetype, on_detect = vim.filetype.match(hint)
  if filetype then
    on_detect = on_detect or function(_) end
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
    function(decorator_factory, window_id)
      set_cursor(window_id, target.row, target.column, target.end_column, width)
      local ok, err =
        pcall(highlight, decorator_factory, bufnr, target.row, target.end_row, target.column, target.end_column, height)
      if ok then
        return nil
      end
      if err:match("out of range") then
        -- workaround for outdated positions in language server
        return err
      end
      error(err)
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
