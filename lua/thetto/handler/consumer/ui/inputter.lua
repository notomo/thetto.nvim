local hl_groups = require("thetto.handler.consumer.ui.highlight_group")

--- @class ThettoUiInputter
--- @field _closed boolean
--- @field _closes fun()[]
--- @field _input_promise table
--- @field private _input_filters ThettoUiInputFilters
--- @field private _window_id integer
--- @field private _bufnr integer
--- @field private _ctx_key string
--- @field private _decorator table
--- @field private _filter_infos table[]
local M = {}
M.__index = M

local _ns_name = "thetto-inputter-highlight"
local _ns = vim.api.nvim_create_namespace(_ns_name)

local _selfs = {}
local _resume_states = {}

local _filetype = "thetto-inputter"

--- @param pipeline ThettoPipeline
function M.open(ctx_key, cwd, closer, layout, on_change, pipeline, insert, source_name)
  local filters = pipeline:filters()

  local resume_state = _resume_states[ctx_key]
    or {
      has_forcus = insert,
      cursor = { 1, 0 },
      is_insert_mode = insert,
      lines = vim.fn["repeat"]({ "" }, #filters),
    }

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = _filetype
  vim.api.nvim_buf_set_name(bufnr, ("thetto://%s/inputter"):format(ctx_key))
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, resume_state.lines)

  local debounce_pairs = vim
    .iter(filters)
    :map(function(filter)
      local debounce_ms = filter.debounce_ms or 50
      local debounce, close = require("thetto.lib.debounce").promise(debounce_ms, function(changed_index)
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return {}, nil
        end

        M._fill_lines(bufnr, filters)
        local inputs = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

        local need_source_invalidation = filter and filter.is_source_input
        local source_input_pattern
        if need_source_invalidation then
          source_input_pattern = inputs[changed_index]
        end

        return inputs, source_input_pattern
      end)
      return {
        debounce = debounce,
        close = close,
      }
    end)
    :totable()
  local debounces = vim
    .iter(debounce_pairs)
    :map(function(x)
      return x.debounce
    end)
    :totable()
  local closes = vim
    .iter(debounce_pairs)
    :map(function(x)
      return x.close
    end)
    :totable()

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
  vim.wo[window_id].winfixbuf = true

  require("thetto.handler.consumer.ui.current_dir").apply(window_id, cwd)

  if resume_state.is_insert_mode then
    vim.cmd.startinsert()
  end
  vim.api.nvim_win_set_cursor(window_id, resume_state.cursor)

  closer:setup_autocmd(window_id)
  require("thetto.core.context").setup_expire(ctx_key, function()
    _resume_states[ctx_key] = nil
  end)

  local tbl = {
    _bufnr = bufnr,
    _window_id = window_id,
    _ctx_key = ctx_key,
    _filter_infos = M._get_filter_infos(filters),
    _decorator = require("thetto.lib.decorator").factory(_ns_name):create(bufnr, true),
    _closed = false,
    _closes = closes,
    _input_filters = require("thetto.handler.consumer.ui.input_filters").new(source_name, filters),
  }
  local self = setmetatable(tbl, M)
  _selfs[bufnr] = self

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(_, _, _, changed_row)
      local changed_index = changed_row + 1
      local debounce = debounces[changed_index]
      if not debounce then
        return
      end
      self._input_promise = debounce(changed_index):next(function(...)
        return on_change(...)
      end)
    end,
  })

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

function M._get_filter_infos(filters)
  return vim
    .iter(filters)
    :map(function(filter)
      if filter.desc then
        return ("[%s:%s]"):format(filter.name, filter.desc)
      end
      return ("[%s]"):format(filter.name)
    end)
    :totable()
end

function M.recall_history(self, offset)
  local row = vim.api.nvim_win_get_cursor(self._window_id)[1]
  local current_line = vim.api.nvim_buf_get_lines(self._bufnr, row - 1, row, false)[1] or ""
  local input_line = self._input_filters:recall_history(row, offset, current_line)
  if not input_line then
    return
  end

  vim.api.nvim_buf_set_lines(self._bufnr, row - 1, row, false, { input_line })
  vim.api.nvim_win_set_cursor(self._window_id, { row, #input_line })
end

function M.highlight(self)
  local line_count = vim.api.nvim_buf_line_count(self._bufnr)
  for i, filter_info in ipairs(self._filter_infos) do
    if i > line_count then
      break
    end
    self._decorator:add_virtual_text(i - 1, 0, { { filter_info, "Comment" } }, {
      virt_text_pos = "right_align",
    })
  end
end

function M.enter(self)
  require("thetto.vendor.misclib.window").safe_enter(self._window_id)
  vim.cmd.startinsert()

  local max_column = vim.fn.col("$")
  local cursor = vim.api.nvim_win_get_cursor(self._window_id)
  if cursor[2] ~= max_column then
    cursor[2] = cursor[2] + 1
    vim.api.nvim_win_set_cursor(self._window_id, cursor)
  end
end

function M.close(self, current_window_id)
  if self._closed then
    return
  end
  self._closed = true
  _selfs[self._bufnr] = nil

  for _, close in ipairs(self._closes) do
    close()
  end

  local current_window_filetype = vim.api.nvim_win_is_valid(current_window_id)
      and vim.bo[vim.api.nvim_win_get_buf(current_window_id)].filetype
    or ""
  local resume_state = {
    has_forcus = current_window_filetype == _filetype,
    cursor = vim.api.nvim_win_get_cursor(self._window_id),
    is_insert_mode = vim.api.nvim_get_mode().mode == "i",
    lines = vim.api.nvim_buf_get_lines(self._bufnr, 0, -1, false),
  }
  _resume_states[self._ctx_key] = resume_state

  self._input_filters:append(resume_state.lines)

  require("thetto.vendor.misclib.window").safe_close(self._window_id)
end

function M.promise(self)
  return self._input_promise
end

return M
