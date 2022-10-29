local filelib = require("thetto.lib.file")

local M = {}

function M.collect(source_ctx)
  local _, err = filelib.find_git_root()
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "--no-pager", "stash", "list", "--pretty=format:%gD %s" }
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local stash_name = output:match("^(%S+)")
    return {
      value = output,
      stash_name = stash_name,
      column_offsets = {
        stash_name = 0,
        description = #stash_name + 1,
      },
    }
  end)
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    start_key = "description",
  },
})

M.kind_name = "word"

local start = function(bufnr, item)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "diff"

  local cmd = { "git", "show", "--date=iso", item.stash_name }
  return require("thetto.util.job").promise(cmd, {
    on_exit = function(output)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      local lines = vim.split(output, "\n", true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end,
  })
end

local open = function(items, f)
  local promises = {}
  for _, item in ipairs(items) do
    local bufnr = vim.api.nvim_create_buf(false, true)
    local promise = start(bufnr, item)
    table.insert(promises, promise)
    f(bufnr)
  end
  return require("thetto.vendor.promise").all(promises)
end

M.actions = {

  action_tab_open = function(items)
    return open(items, function(bufnr)
      vim.cmd.tabedit()
      vim.cmd.buffer(bufnr)
    end)
  end,

  action_preview = function(items, _, ctx)
    local item = items[1]
    if not item then
      return nil
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].filetype = "diff"

    local cmd = { "git", "--no-pager", "show", "--date=iso", item.stash_name }
    local promise = require("thetto.util.job").promise(cmd, {
      on_exit = function(output)
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        local lines = vim.split(output, "\n", true)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      end,
    })
    ctx.ui:open_preview(item, { raw_bufnr = bufnr })
    return promise
  end,
}

return M
