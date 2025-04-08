local M = {}

-- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#completionItemKind
local completionItemKind = {
  [1] = "Text",
  [2] = "Method",
  [3] = "Function",
  [4] = "Constructor",
  [5] = "Field",
  [6] = "Variable",
  [7] = "Class",
  [8] = "Interface",
  [9] = "Module",
  [10] = "Property",
  [11] = "Unit",
  [12] = "Value",
  [13] = "Enum",
  [14] = "Keyword",
  [15] = "Snippet",
  [16] = "Color",
  [17] = "File",
  [18] = "Reference",
  [19] = "Folder",
  [20] = "EnumMember",
  [21] = "Constant",
  [22] = "Struct",
  [23] = "Event",
  [24] = "Operator",
  [25] = "TypeParameter",
}

function M.collect(source_ctx)
  return function(observer)
    local bufnr = source_ctx.bufnr
    local method = vim.lsp.protocol.Methods.textDocument_completion
    local cancel = require("thetto.util.lsp").request({
      bufnr = bufnr,
      method = method,
      clients = vim.lsp.get_clients({
        bufnr = bufnr,
        method = method,
      }),
      params = function(client)
        return vim.lsp.util.make_position_params(source_ctx.window_id, client.offset_encoding)
      end,
      observer = {
        next = function(result)
          local items = vim
            .iter(result.items)
            :map(function(item)
              return {
                value = item.insertText or item.label,
                desc = item.label,
                kind_label = completionItemKind[item.kind],
              }
            end)
            :filter(function(item)
              return item.kind_label ~= "Snippet" and item.kind_label ~= "Text"
            end)
            :totable()
          observer:next(items)
        end,
        complete = function()
          observer:complete()
        end,
        error = function(err)
          observer:error(err)
        end,
      },
    })
    return cancel
  end
end

function M.set_completion_info(index)
  local window_id = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(window_id)
  local method = vim.lsp.protocol.Methods.textDocument_hover
  local cancel = require("thetto.util.lsp").request({
    bufnr = bufnr,
    method = method,
    clients = vim.lsp.get_clients({
      bufnr = bufnr,
      method = method,
    }),
    params = function(client)
      return vim.lsp.util.make_position_params(window_id, client.offset_encoding)
    end,
    observer = {
      next = function(result)
        local content = result.contents.value
        local t = vim.api.nvim__complete_set(index, { info = content })
        if vim.tbl_isempty(t) then
          return
        end

        vim.bo[t.bufnr].filetype = "markdown"
        local info_window_id = t.winid
        vim.wo[info_window_id].wrap = true
        vim.api.nvim_win_set_config(info_window_id, {
          border = "solid",
          fixed = true,
        })
      end,
      complete = function() end,
      error = function(err)
        require("thetto.lib.message").warn(err)
      end,
    },
  })
  return cancel
end

M.kind_name = "word"

M.cwd = require("thetto.util.cwd").project()

return M
