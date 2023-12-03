local UI = {}
UI.__index = UI

function UI.new(filters, on_change, on_discard)
  local group_name = "thetto_ui_" .. tostring(vim.uv.hrtime())
  local group = vim.api.nvim_create_augroup(group_name, {})
  local pattern = { "_thetto_closed_" .. group_name }
  local setup_close_autocmd = function(window_id)
    vim.api.nvim_create_autocmd({ "WinClosed" }, {
      pattern = { "*" },
      callback = function(args)
        if tonumber(args.file) ~= window_id then
          return
        end
        vim.api.nvim_exec_autocmds("User", {
          pattern = pattern,
          group = group,
        })
        return true
      end,
    })
  end

  local layout = require("thetto2.handler.consumer.ui.layout").new()
  local item_list = require("thetto2.handler.consumer.ui.item_list").open(setup_close_autocmd, layout)
  local inputter = require("thetto2.handler.consumer.ui.inputter").open(setup_close_autocmd, layout, filters, on_change)

  vim.api.nvim_create_autocmd({ "User" }, {
    group = group,
    pattern = pattern,
    callback = function()
      item_list:close()
      inputter:close()
      on_discard()
    end,
    once = true,
  })

  -- setup highligh provider
  -- setup on moved autocmd

  local tbl = {
    _item_list = item_list,
    _inputter = inputter,
  }
  return setmetatable(tbl, UI)
end

function UI.consume(self, items)
  self._item_list:redraw(items)
end

function UI.on_error(self, err)
  error(err)
end

function UI.complete(self) end

return UI
