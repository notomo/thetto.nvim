local M = {}

function M.collect(source_ctx)
  if not vim.api.nvim_buf_is_valid(source_ctx.bufnr) then
    return nil, "invalid buffer: " .. source_ctx.bufnr
  end

  local cmd = { "jq", source_ctx.pattern }
  return require("thetto.util.job").run(cmd, source_ctx, function(output, code)
    local is_error = code ~= 0
    return {
      value = output,
      is_error = is_error,
    }
  end, {
    input = vim.api.nvim_buf_get_lines(source_ctx.bufnr, 0, -1, false),
    stop_on_error = false,
  })
end

vim.api.nvim_set_hl(0, "ThettoJqError", { default = true, link = "WarningMsg" })

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "ThettoJqError",
    filter = function(item)
      return item.is_error
    end,
  },
})

M.kind_name = "word"

M.modify_pipeline = require("thetto2.util.pipeline").prepend({
  require("thetto2.util.filter").by_name("source_input"),
})

return M
