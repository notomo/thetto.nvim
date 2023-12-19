local M = {}
M.__index = M

local _states = {}

function M.open(ctx_key, cwd, closer, layout, raw_input_filters, on_change)
  local state = _states[ctx_key] or {
    has_forcus = true,
    cursor = { 1, 0 },
    is_insert_mode = true,
  }

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "thetto2-input"
  vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/inputter"):format(ctx_key))

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(_, _, _, _)
      on_change(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return require("thetto2.core.pipeline_context").new()
        end
        local inputs = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
        return require("thetto2.core.pipeline_context").new(inputs)
      end)
    end,
  })

  local input_height = math.max(#raw_input_filters, 1)
  local window_id = vim.api.nvim_open_win(bufnr, state.has_forcus, {
    width = layout.width - 2,
    height = input_height,
    relative = "editor",
    row = layout.row + layout.height + 1,
    col = layout.column,
    external = false,
    style = "minimal",
    border = {
      { "", "ThettoInput" },
      { "", "ThettoInput" },
      { " ", "ThettoInput" },
      { " ", "ThettoInput" },
      { "", "ThettoInput" },
      { "", "ThettoInput" },
      { " ", "ThettoInput" },
      { " ", "ThettoInput" },
    },
  })

  vim.api.nvim_win_call(window_id, function()
    local ok, result = pcall(require("thetto2.lib.file").lcd, cwd)
    if not ok then
      vim.notify("[thetto] " .. result, vim.log.levels.WARN)
    end
  end)

  vim.api.nvim_win_set_cursor(window_id, state.cursor)
  if state.is_insert_mode then
    vim.cmd.startinsert()
  end

  closer:setup_autocmd(window_id)

  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = { "thetto_ctx_deleted_" .. ctx_key },
    callback = function()
      _states[ctx_key] = nil
    end,
    once = true,
  })

  local tbl = {
    _bufnr = bufnr,
    _window_id = window_id,
    _ctx_key = ctx_key,
    _closed = false,
  }
  return setmetatable(tbl, M)
end

function M.enter(self)
  require("thetto2.vendor.misclib.window").safe_enter(self._window_id)
end

function M.close(self)
  if self._closed then
    return
  end
  self._closed = true

  local state = {
    has_forcus = vim.api.nvim_get_current_win() == self._window_id,
    cursor = vim.api.nvim_win_get_cursor(self._window_id),
    is_insert_mode = vim.api.nvim_get_mode().mode == "i",
  }
  _states[self._ctx_key] = state

  require("thetto2.vendor.misclib.window").safe_close(self._window_id)
end

return M
