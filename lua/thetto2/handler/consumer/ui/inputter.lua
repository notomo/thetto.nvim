local hl_groups = require("thetto2.handler.consumer.ui.highlight_group")

--- @class ThettoUiInputter
--- @field _closed boolean
local M = {}
M.__index = M

local _ns_name = "thetto2-inputter-highlight"
local _ns = vim.api.nvim_create_namespace(_ns_name)

local _selfs = {}
local _resume_states = {}

--- @param pipeline ThettoPipeline
function M.open(ctx_key, cwd, closer, layout, on_change, pipeline)
  local filters = pipeline:filters()

  local resume_state = _resume_states[ctx_key]
    or {
      has_forcus = true,
      cursor = { 1, 0 },
      is_insert_mode = true,
      lines = vim.fn["repeat"]({ "" }, #filters),
    }

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "thetto2-input"
  vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/inputter"):format(ctx_key))
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, resume_state.lines)

  local is_interactive = pipeline:has_source_input()
  local debounces = vim
    .iter(filters)
    :map(function(filter)
      local debounce_ms = filter.debounce_ms or 50
      return require("thetto2.lib.debounce").promise(debounce_ms, function(changed_index)
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end

        M._fill_lines(bufnr, filters)
        local inputs = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

        local need_source_invalidation = filter and filter.is_source_input
        local pattern
        if need_source_invalidation then
          pattern = inputs[changed_index]
        end

        local source_input = {
          pattern = pattern,
          is_interactive = is_interactive,
        }
        return require("thetto2.core.pipeline_context").new(inputs, source_input)
      end)
    end)
    :totable()

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(_, _, _, changed_row)
      local changed_index = changed_row + 1
      local debounce = debounces[changed_index]
      debounce(changed_index):next(function(...)
        return on_change(...)
      end)
    end,
  })

  local window_id = vim.api.nvim_open_win(bufnr, resume_state.has_forcus, {
    width = layout.width,
    height = layout.height,
    relative = "editor",
    row = layout.row,
    col = layout.column,
    external = false,
    style = "minimal",
    border = {
      { "" },
      { "" },
      { " ", hl_groups.ThettoUiBorder },
      { " ", hl_groups.ThettoUiBorder },
      { "" },
      { "" },
      { " ", hl_groups.ThettoUiBorder },
      { " ", hl_groups.ThettoUiBorder },
    },
  })

  vim.api.nvim_win_call(window_id, function()
    local ok, result = pcall(require("thetto2.lib.file").lcd, cwd)
    if not ok then
      vim.notify("[thetto] " .. result, vim.log.levels.WARN)
    end
  end)

  vim.api.nvim_win_set_cursor(window_id, resume_state.cursor)
  if resume_state.is_insert_mode then
    vim.cmd.startinsert()
  end

  closer:setup_autocmd(window_id)

  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = { "thetto_ctx_deleted_" .. ctx_key },
    callback = function()
      _resume_states[ctx_key] = nil
    end,
    once = true,
  })

  local tbl = {
    _bufnr = bufnr,
    _window_id = window_id,
    _ctx_key = ctx_key,
    _filters = filters,
    _decorator = require("thetto2.lib.decorator").factory(_ns_name):create(bufnr, true),
    _closed = false,
  }
  local self = setmetatable(tbl, M)
  _selfs[bufnr] = self

  vim.api.nvim_set_decoration_provider(_ns, {})
  vim.api.nvim_set_decoration_provider(_ns, {
    on_win = function(_, _, self_bufnr, _, _)
      local inputter = _selfs[self_bufnr]
      if not inputter then
        return false
      end

      inputter:highlight()

      return false
    end,
  })

  return self
end

function M._fill_lines(bufnr, filters)
  local height = #filters

  local line_count_diff = height - vim.api.nvim_buf_line_count(bufnr)
  if line_count_diff > 0 then
    vim.api.nvim_buf_set_lines(bufnr, height - 1, -1, false, vim.fn["repeat"]({ "" }, line_count_diff))
  elseif line_count_diff < 0 then
    vim.api.nvim_buf_set_lines(bufnr, height, -1, false, {})
  end
end

function M.highlight(self)
  local line_count = vim.api.nvim_buf_line_count(self._bufnr)
  for i, filter in ipairs(self._filters) do
    if i > line_count then
      break
    end
    local filter_info = ("[%s]"):format(filter.name)
    self._decorator:add_virtual_text(i - 1, 0, { { filter_info, "Comment" } }, {
      virt_text_pos = "right_align",
    })
  end
end

function M.enter(self)
  require("thetto2.vendor.misclib.window").safe_enter(self._window_id)
  vim.cmd.startinsert()
end

function M.close(self, current_window_id)
  if self._closed then
    return
  end
  self._closed = true
  _selfs[self._bufnr] = nil

  local resume_state = {
    has_forcus = current_window_id == self._window_id,
    cursor = vim.api.nvim_win_get_cursor(self._window_id),
    is_insert_mode = vim.api.nvim_get_mode().mode == "i",
    lines = vim.api.nvim_buf_get_lines(self._bufnr, 0, -1, false),
  }
  _resume_states[self._ctx_key] = resume_state

  require("thetto2.vendor.misclib.window").safe_close(self._window_id)
end

return M
