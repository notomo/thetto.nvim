local M = {}

local completionItemKind = vim.lsp.protocol.CompletionItemKind
local insertTextFormat = vim.lsp.protocol.InsertTextFormat

local content_modified_err = -32801

local get_last_char = function(source_ctx)
  local cursor = vim.api.nvim_win_get_cursor(source_ctx.window_id)
  local row = cursor[1]
  local current_line = vim.api.nvim_buf_get_lines(source_ctx.bufnr, row - 1, row, false)[1]
  local line = current_line:sub(1, cursor[2])
  local last = line:sub(-1)
  return last
end

function M.collect(source_ctx)
  return function(observer)
    local last_char = get_last_char(source_ctx)
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
        local params = vim.lsp.util.make_position_params(source_ctx.window_id, client.offset_encoding)
        if params.position.line < 0 or params.position.character < 0 then
          return nil
        end

        local trigger_characters = vim.tbl_get(client.server_capabilities, "completionProvider", "triggerCharacters")
        if not source_ctx.is_manual and vim.tbl_contains(trigger_characters, last_char) then
          return vim.tbl_extend("force", params, {
            context = {
              triggerKind = vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter,
              triggerCharacter = last_char,
            },
          })
        end
        return vim.tbl_extend("force", params, {
          context = {
            triggerKind = vim.lsp.protocol.CompletionTriggerKind.Invoked,
          },
        })
      end,
      observer = {
        next = function(result, ctx)
          local items = vim
            .iter(result.items)
            :map(function(item)
              local descs = { item.label }
              local detail = vim.tbl_get(item, "labelDetails", "description")
              if detail then
                table.insert(descs, detail)
              end

              local value = item.insertText or item.label
              return {
                value = value,
                desc = table.concat(descs, " "),
                kind_label = completionItemKind[item.kind],
                original_item = item,
                has_edit = item.textEdit ~= nil
                  or (item.insertText and item.insertTextFormat == insertTextFormat.Snippet),
                deprecated = item.deprecated,
                client_id = ctx.client_id,
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

local ns = vim.api.nvim_create_namespace("thetto.lsp.completion")

function M.edit_on_completion(bufnr, _, original_item, offset)
  if not original_item.textEdit and original_item.insertTextFormat ~= insertTextFormat.Snippet then
    return
  end

  local row, column = unpack(vim.api.nvim_win_get_cursor(0))
  local text_edit
  if original_item.textEdit then
    text_edit = original_item.textEdit
  else
    text_edit = {
      newText = original_item.insertText,
      range = {
        start = {
          line = row - 1,
          character = offset - 1,
        },
        ["end"] = {
          line = row - 1,
          character = column,
        },
      },
    }
  end

  local group = vim.api.nvim_create_augroup("thetto.lsp.completion", {})
  vim.api.nvim_create_autocmd({ "CompleteChanged", "ModeChanged" }, {
    buffer = 0,
    group = group,
    callback = function()
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end,
  })

  local lines = vim.split(text_edit.newText or "", "\n", { plain = true })
  local range = text_edit.range
  local first_line = lines[1]

  local overlay_args = {}
  if range.start.character < column then
    local line = first_line:sub(0, column - range.start.character)
    overlay_args = {
      s = range.start.line,
      e = range.start.character,
      opts = {
        end_line = range.start.line,
        end_col = column,
        virt_text_pos = "overlay",
        virt_text = { { line, "Comment" } },
      },
    }
  end

  local line = first_line:sub(column - range.start.character + 1)
  local opts = {
    end_line = range["end"].line,
    end_col = range["end"].character,
    virt_text_pos = "inline",
    virt_text = { { line, "Comment" } },
  }
  local virt_lines = vim
    .iter(lines)
    :skip(1)
    :map(function(x)
      return { { x, "Comment" } }
    end)
    :totable()
  if #virt_lines > 0 then
    opts.virt_lines = virt_lines
  end
  vim.schedule(function()
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    if not vim.tbl_isempty(overlay_args) then
      vim.api.nvim_buf_set_extmark(bufnr, ns, overlay_args.s, overlay_args.e, overlay_args.opts)
    end
    vim.api.nvim_buf_set_extmark(bufnr, ns, range.start.line, column, opts)
  end)
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
        vim.wo[info_window_id][0].wrap = true
        vim.api.nvim_win_set_config(info_window_id, {
          border = "solid",
          fixed = true,
        })
      end,
      complete = function() end,
      error = function(err)
        if err and err.code == content_modified_err then
          return
        end
        require("thetto.lib.message").warn(err)
      end,
    },
  })
  return cancel
end

function M.resolve(params, client_id, offset)
  local window_id = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(window_id)

  if params.insertText and params.insertTextFormat == insertTextFormat.Snippet then
    local row, column = unpack(vim.api.nvim_win_get_cursor(window_id))
    vim.api.nvim_buf_set_text(bufnr, row - 1, offset - 1, row - 1, column, { "" })
    vim.snippet.expand(params.insertText)
  elseif params.textEdit then
    local client = assert(vim.lsp.get_clients({ id = client_id })[1])
    vim.lsp.util.apply_text_edits({ params.textEdit }, bufnr, client.offset_encoding)
    vim.api.nvim_win_set_cursor(window_id, {
      params.textEdit.range["end"].line + 1,
      params.textEdit.range["end"].character + #params.textEdit.newText - 1,
    })
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
        if err and err.code == content_modified_err then
          return
        end
        require("thetto.lib.message").warn(err)
      end,
    },
  })
  return cancel
end

M.kind_name = "word"

M.cwd = require("thetto.util.cwd").project()

return M
