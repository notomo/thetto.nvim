local M = {}

function M.collect(source_ctx)
  local bufnrs = vim.tbl_keys(vim.iter(vim.api.nvim_tabpage_list_wins(0)):fold({}, function(acc, window_id)
    local bufnr = vim.api.nvim_win_get_buf(window_id)
    acc[bufnr] = true
    return acc
  end))

  local to_items = function(data, cursor_word)
    local already = { [cursor_word] = cursor_word }
    local items = vim
      .iter(vim.split(data, [=[[^a-zA-Z0-9_]+]=], { trimempty = true }))
      :map(function(word)
        if already[word] or #word <= 2 then
          return nil
        end
        already[word] = true
        return {
          value = word,
        }
      end)
      :totable()
    return vim.mpack.encode(items)
  end

  return function(observer)
    local work_observer = require("thetto.util.job.work_observer").new(observer, to_items, function(encoded)
      return vim.mpack.decode(encoded)
    end)

    local cursor_word = require("thetto.lib.cursor").word(source_ctx.window_id).str or ""

    vim.iter(bufnrs):each(function(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      work_observer:queue(table.concat(lines, "\n"), cursor_word)
    end)
    work_observer:complete()
  end
end

M.kind_name = "word"
M.kind_label = "Buffer"

return M
