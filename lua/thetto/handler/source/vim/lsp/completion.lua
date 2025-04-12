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

local insertTextFormat = {
  PlainText = 1,
  Snippet = 2,
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
              local descs = { item.label }
              local detail = vim.tbl_get(item, "labelDetails", "description")
              if detail then
                table.insert(descs, detail)
              end

              return {
                value = item.insertText or item.label,
                desc = table.concat(descs, " "),
                kind_label = completionItemKind[item.kind],
                original_item = item,
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

function M.resolve(params)
  local window_id = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(window_id)

  if params.insertText and params.insertTextFormat == insertTextFormat.Snippet then
    local row, column = unpack(vim.api.nvim_win_get_cursor(window_id))
    vim.api.nvim_buf_set_text(bufnr, row - 1, column - #params.insertText, row - 1, column, { "" })
    vim.snippet.expand(params.insertText)
  end

  local method = vim.lsp.protocol.Methods.completionItem_resolve
  local cancel = require("thetto.util.lsp").request({
    bufnr = bufnr,
    method = method,
    clients = vim.lsp.get_clients({
      bufnr = bufnr,
      method = method,
    }),
    params = function()
      return params
    end,
    server_capabilities = { "completionProvider", "resolveProvider" },
    observer = {
      next = function(result, ctx)
        if result.additionalTextEdits then
          local client = assert(vim.lsp.get_clients({ id = ctx.client_id })[1])
          vim.lsp.util.apply_text_edits(result.additionalTextEdits, bufnr, client.offset_encoding)
        end
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
