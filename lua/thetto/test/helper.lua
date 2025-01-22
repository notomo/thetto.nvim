local helper = require("vusted.helper")
local plugin_name = helper.get_module_root(...)

helper.root = helper.find_plugin_root(plugin_name)
vim.opt.packpath:prepend(vim.fs.joinpath(helper.root, "spec/.shared/packages"))
require("assertlib").register(require("vusted.assert").register)

function helper.before_each()
  vim.o.showmode = false -- to clean test log
end

function helper.after_each()
  helper.cleanup()
  helper.cleanup_loaded_modules(plugin_name)
end

function helper.on_finished()
  local finished = false
  return setmetatable({
    wait = function()
      local ok = vim.wait(1000, function()
        return finished
      end, 10, false)
      if not ok then
        error("wait timeout")
      end
    end,
  }, {
    __call = function()
      finished = true
    end,
  })
end

function helper.wait(promise)
  local on_finished = helper.on_finished()
  promise:finally(function()
    on_finished()
  end)
  on_finished:wait()
end

function helper.input(text)
  vim.api.nvim_put({ text }, "c", true, true)
  local p = require("thetto").call_consumer("wait")
  helper.wait(p)
end

function helper.go_to_sidecar(title)
  local preview_window_id = vim.iter(vim.api.nvim_tabpage_list_wins(0)):find(function(window_id)
    local config = vim.api.nvim_win_get_config(window_id)
    return vim.tbl_get(config, "title", 1, 1) == title
  end)
  vim.api.nvim_set_current_win(preview_window_id)
end

local asserts = require("vusted.assert").asserts

asserts.create("lines"):register_eq(function()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end)

function helper.typed_assert(assert)
  local x = require("assertlib").typed(assert)
  ---@cast x +{lines:fun(want)}
  return x
end

return helper
