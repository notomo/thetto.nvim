--- @class ThettoUiCloser
--- @field _group integer
--- @field _pattern string
--- @field _original_window_id integer
local M = {}
M.__index = M

function M.new()
  local original_window_id = vim.api.nvim_get_current_win()
  local group_name = "thetto_ui_" .. tostring(vim.uv.hrtime())
  local group = vim.api.nvim_create_augroup(group_name, {})
  local pattern = "_thetto_closed_" .. group_name
  local tbl = {
    _group = group,
    _pattern = pattern,
    _original_window_id = original_window_id,
  }
  return setmetatable(tbl, M)
end

function M.setup_autocmd(self, window_id)
  vim.api.nvim_create_autocmd({ "WinClosed" }, {
    group = self._group,
    pattern = { "*" },
    callback = function(args)
      if tonumber(args.file) ~= window_id then
        return
      end
      self:execute()
      return true
    end,
  })

  local original_bufnr = vim.api.nvim_win_get_buf(window_id)

  vim.api.nvim_create_autocmd({ "BufLeave" }, {
    group = self._group,
    buffer = original_bufnr,
    callback = function()
      vim.api.nvim_create_autocmd({ "BufEnter" }, {
        group = self._group,
        pattern = { "*" },
        callback = function()
          local bufnr = vim.api.nvim_win_get_buf(window_id)
          if bufnr == original_bufnr then
            return
          end
          self:execute()
        end,
        once = true,
      })
    end,
  })

  vim.api.nvim_create_autocmd({ "FileType" }, {
    group = self._group,
    pattern = { vim.bo[original_bufnr].filetype },
    callback = function(args)
      local bufnr = args.buf
      if bufnr == original_bufnr then
        return
      end
      self:execute()
      return true
    end,
  })
end

function M.setup(self, handler)
  vim.api.nvim_create_autocmd({ "User" }, {
    group = self._group,
    pattern = self._pattern,
    callback = function()
      handler()
      vim.api.nvim_clear_autocmds({ group = self._group })
      if vim.api.nvim_win_is_valid(self._original_window_id) then
        vim.api.nvim_set_current_win(self._original_window_id)
      end
    end,
    once = true,
  })
end

function M.execute(self)
  vim.api.nvim_exec_autocmds("User", {
    pattern = self._pattern,
    group = self._group,
    modeline = false,
  })
end

return M
