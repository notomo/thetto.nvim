local M = {}
M.__index = M

function M.new()
  local group_name = "thetto_ui_" .. tostring(vim.uv.hrtime())
  local group = vim.api.nvim_create_augroup(group_name, {})
  local pattern = "_thetto_closed_" .. group_name
  local tbl = {
    _group = group,
    _pattern = pattern,
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
      vim.api.nvim_exec_autocmds("User", {
        pattern = self._pattern,
        group = self._group,
        modeline = false,
      })
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
          vim.api.nvim_exec_autocmds("User", {
            pattern = self._pattern,
            group = self._group,
            modeline = false,
          })
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
      vim.api.nvim_exec_autocmds("User", {
        pattern = self._pattern,
        group = self._group,
        modeline = false,
      })
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
    end,
    once = true,
  })
end

return M
