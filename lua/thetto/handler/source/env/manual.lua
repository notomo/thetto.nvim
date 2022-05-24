local M = {}

function M.collect(self)
  if vim.fn.has("win32") == 1 then
    return nil, nil, "not supported in windows"
  end

  local job = self.jobs.new({ "apropos", "-l", "." }, {
    on_exit = function(job_self)
      local items = {}
      local outputs = job_self:get_stdout()
      for _, output in ipairs(outputs) do
        local name, desc = output:match("(%S+%s%S+)%s+-%s(.*)")
        name = name:gsub(" ", "")
        table.insert(items, {
          value = name,
          desc = ("%s - %s"):format(name, desc),
          column_offsets = { value = 0, _desc = #name + 1 },
        })
      end
      self:append(items)
    end,
    on_stderr = self.jobs.print_stderr,
  })
  return {}, job
end

vim.cmd("highlight default link ThettoManualDescription Comment")

M.highlight = require("thetto.util").highlight.columns({
  {
    group = "ThettoManualDescription",
    start_key = "_desc",
  },
})

M.kind_name = "env/manual"

return M
