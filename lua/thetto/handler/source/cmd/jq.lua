local M = {}

function M.collect(self, source_ctx)
  local cmd = { "jq", source_ctx.pattern }
  return require("thetto.util").job.run(cmd, source_ctx, function(output, code)
    local is_error = code ~= 0
    return {
      value = output,
      is_error = is_error,
    }
  end, {
    input = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false),
    stop_on_error = false,
    to_outputs = function(job)
      return job:get_output()
    end,
  })
end

vim.api.nvim_set_hl(0, "ThettoJqError", { default = true, link = "WarningMsg" })

M.highlight = require("thetto.util").highlight.columns({
  {
    group = "ThettoJqError",
    filter = function(item)
      return item.is_error
    end,
  },
})

M.kind_name = "word"

return M
