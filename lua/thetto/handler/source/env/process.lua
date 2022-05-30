local M = {}

function M.collect(_, source_ctx)
  local cmd = { "ps", "--no-headers", "faxo", "pid,user,command" }
  local remove_header = function(_) end
  local to_item = function(output)
    local splitted = vim.split(output:gsub("^%s+", ""), "%s")
    return { value = output, pid = splitted[1] }
  end
  if vim.fn.has("mac") == 1 then
    cmd = { "ps", "-axo", "pid,user,command" }
    remove_header = function(outputs)
      table.remove(outputs, 1)
    end
  elseif vim.fn.has("win32") == 1 then
    cmd = { "tasklist", "/NH", "/FO", "CSV" }
    remove_header = function(outputs)
      table.remove(outputs, 1)
    end
    to_item = function(output)
      local splitted = vim.split(output:gsub("^%s+", ""), '","')
      local pid = splitted[2]
      local value = ("%s %d"):format(splitted[1]:sub(2), pid)
      return { value = value, pid = pid }
    end
  end

  return require("thetto.util").job.run(cmd, source_ctx, to_item, {
    to_outputs = function(job)
      local outputs = job:get_stdout()
      remove_header(outputs)
      return outputs
    end,
  })
end

M.kind_name = "env/process"

return M
