local M = {}

function M.collect(_, source_ctx)
  if vim.fn.has("win32") == 1 then
    return nil, "not supported in windows"
  end

  local cmd = { "apropos", "-l", "." }
  return require("thetto.util").job.start(cmd, source_ctx, function(output)
    local name, desc = output:match("(%S+%s%S+)%s+-%s(.*)")
    name = name:gsub(" ", "")
    return {
      value = name,
      desc = ("%s - %s"):format(name, desc),
      column_offsets = { value = 0, _desc = #name + 1 },
    }
  end)
end

vim.api.nvim_set_hl(0, "ThettoManualDescription", { default = true, link = "Comment" })

M.highlight = require("thetto.util").highlight.columns({
  {
    group = "ThettoManualDescription",
    start_key = "_desc",
  },
})

M.kind_name = "env/manual"

return M
