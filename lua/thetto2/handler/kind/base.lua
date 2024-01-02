local M = {}

M.opts = {
  yank = { key = "value", register = "+" },
  append = { key = "value", type = "" },
}

M.behaviors = {
  debug_print = { quit = false },
}

function M.action_debug_print(items)
  for _, item in ipairs(items) do
    require("thetto.vendor.misclib.message").info(vim.inspect(item))
  end
end

function M.action_debug_dump(items)
  for _, item in ipairs(items) do
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].filetype = "json"

    local lines = { vim.json.encode(item) }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    require("thetto.lib.buffer").open_scratch_tab()
    vim.cmd.buffer(bufnr)
    vim.cmd("%!jq '.'")
  end
end

function M.action_echo(items)
  for _, item in ipairs(items) do
    require("thetto.vendor.misclib.message").info(item.value)
  end
end

function M.action_yank(items, action_ctx)
  local values = vim.tbl_map(function(item)
    return item[action_ctx.opts.key]
  end, items)
  local value = table.concat(values, "\n")
  if value ~= "" then
    vim.fn.setreg(action_ctx.opts.register, value)
    require("thetto.vendor.misclib.message").info("yank: " .. value)
  end
end

function M.action_append(items, action_ctx)
  for _, item in ipairs(items) do
    vim.api.nvim_put({ item[action_ctx.opts.key] }, action_ctx.opts.type, true, true)
  end
end

M.default_action = "echo"

return M
