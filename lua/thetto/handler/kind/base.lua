local M = {}

M.name = "base"
M.opts = {}

function M.action_debug_print(items)
  for _, item in ipairs(items) do
    require("thetto.lib.message").info(vim.inspect(item))
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
    require("thetto.lib.message").info(item.value)
  end
end

M.opts.yank = {
  key = "value",
  register = "+",
  convert = function(values)
    return values
  end,
}
function M.action_yank(items, action_ctx)
  local values = vim
    .iter(items)
    :map(function(item)
      return item[action_ctx.opts.key]
    end)
    :totable()
  local value = table.concat(action_ctx.opts.convert(values), "\n")
  if value ~= "" then
    vim.fn.setreg(action_ctx.opts.register, value)
    require("thetto.lib.message").info("yank: " .. value)
  end
end

M.opts.append = { key = "value", type = "" }
function M.action_append(items, action_ctx)
  for _, item in ipairs(items) do
    vim.api.nvim_put({ item[action_ctx.opts.key] }, action_ctx.opts.type, true, true)
  end
end

M.default_action = "echo"

return M
