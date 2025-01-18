local M = {}

function M.collect(source_ctx)
  return function(observer)
    vim.system(
      { "zsh", "-i", "-c", "echo ${HISTFILE}" },
      {
        cwd = source_ctx.cwd,
      },
      vim.schedule_wrap(function(o)
        local path = vim.trim(o.stdout)
        if not path then
          observer:next({})
          observer:complete()
        end

        local f = io.open(path, "r")
        if not f then
          observer:error("cannot open: " .. path)
          return
        end
        local lines = vim.fn.reverse(vim.split(f:read("*a"), "\n", { plain = true }))
        f:close()

        local items = vim
          .iter(lines)
          :map(function(s)
            local cmd = s:gsub(".*;", "")
            if cmd == "" then
              return nil
            end
            return {
              value = cmd,
              cwd = source_ctx.cwd,
              shell = "zsh",
            }
          end)
          :totable()

        observer:next(items)
        observer:complete()
      end)
    )
  end
end

M.kind_name = "cmd/shell/cmd"

return M
