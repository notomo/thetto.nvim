local helper = require("vusted.helper")
local plugin_name = helper.get_module_root(...)

helper.root = helper.find_plugin_root(plugin_name)
vim.opt.packpath:prepend(vim.fs.joinpath(helper.root, "spec/.shared/packages"))
require("assertlib").register(require("vusted.assert").register)

local ui_open = vim.ui.open

function helper.before_each()
  vim.o.showmode = false
  vim.o.swapfile = false
  vim.ui.open = ui_open
  helper.test_data = require("thetto.vendor.misclib.test.data_dir").setup(helper.root)
  helper.test_data:cd("")
end

function helper.after_each()
  helper.test_data:teardown()
  helper.cleanup()
  helper.cleanup_loaded_modules(plugin_name)
end

function helper.set_lines(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(lines, "\n"))
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

function helper.wait_redraw(f)
  f = f or function() end
  local on_finished = helper.on_finished()
  vim.api.nvim_create_autocmd({ "User" }, {
    group = vim.api.nvim_create_augroup("thetto_test", {}),
    pattern = { "ThettoTestRedrawn" },
    callback = function()
      on_finished()
      return true
    end,
  })
  require("thetto.view.ui")._test = true
  f()
  on_finished:wait()
end

function helper.sync_input(texts)
  helper.wait_redraw(function()
    local text = texts[1]
    vim.api.nvim_put({ text }, "c", true, true)
  end)
end

function helper.sync_start(...)
  local promise = require("thetto").start(...)
  helper.wait(promise)
end

function helper.sync_execute(...)
  local promise = require("thetto").execute(...)
  helper.wait(promise)
end

function helper.sync_reload(...)
  local promise = require("thetto").reload(...)
  helper.wait(promise)
end

function helper.sync_resume(...)
  local promise = require("thetto").resume(...)
  helper.wait(promise)
end

function helper.search(pattern)
  local result = vim.fn.search(pattern)
  if result == 0 then
    local info = debug.getinfo(2)
    local pos = ("%s:%d"):format(info.source, info.currentline)
    local lines = table.concat(vim.fn.getbufline("%", 1, "$"), "\n")
    local msg = ("on %s: `%s` not found in buffer:\n%s"):format(pos, pattern, lines)
    assert(false, msg)
  end
  return result
end

function helper.path(path)
  return helper.test_data:path(path or "")
end

function helper.window_count()
  return vim.fn.tabpagewinnr(vim.fn.tabpagenr(), "$")
end

function helper.sub_windows()
  local windows = {}
  for bufnr, id in require("thetto.lib.buffer").in_tabpage(0) do
    local config = vim.api.nvim_win_get_config(id)
    if config.relative ~= "" and vim.bo[bufnr].filetype == "" then
      table.insert(windows, id)
    end
  end
  return windows
end

local asserts = require("vusted.assert").asserts

asserts.create("register_value"):register_eq(function(name)
  return vim.fn.getreg(name)
end)

asserts.create("line_count"):register_eq(function()
  return vim.api.nvim_buf_line_count(0)
end)

asserts.create("dir_name"):register_eq(function()
  return vim.fn.fnamemodify(vim.fn.bufname("%"), ":h:t")
end)

asserts.create("current_dir"):register_eq(function()
  return vim.fn.getcwd():gsub(helper.test_data:path("?"), "")
end)

return helper
