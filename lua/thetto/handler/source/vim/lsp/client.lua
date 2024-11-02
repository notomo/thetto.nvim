local M = {}

function M.collect()
  return vim
    .iter(vim.lsp.get_clients())
    :map(function(client)
      local config = {
        cmd = client.config.cmd,
        cmd_cwd = client.config.cmd_cwd,
        root_dir = client.config.root_dir,
      }
      local desc = ("%d %s %s"):format(client.id, client.name, vim.inspect(config, { newline = " ", indent = "" }))
      return {
        value = client.name,
        client_id = client.id,
        desc = desc,
        column_offsets = {
          value = #tostring(client.id) + 1,
        },
      }
    end)
    :totable()
end

M.kind_name = "word"

M.cwd = require("thetto.util.cwd").project()

M.actions = {
  action_show_server_capabilities = function(items)
    local item = items[1]
    if not item then
      return
    end

    local client = vim.lsp.get_clients({ id = item.client_id })[1]
    if not item then
      return
    end

    local content = vim.inspect(client.server_capabilities)
    require("thetto.lib.buffer").open_scratch_tab()
    vim.bo.filetype = "lua"
    local lines = vim.split(content, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  end,

  action_show_capabilities = function(items)
    local item = items[1]
    if not item then
      return
    end

    local client = vim.lsp.get_clients({ id = item.client_id })[1]
    if not item then
      return
    end

    local content = vim.inspect({
      capabilities = client.capabilities,
      dynamic_capabilities = client.dynamic_capabilities,
    })
    require("thetto.lib.buffer").open_scratch_tab()
    vim.bo.filetype = "lua"
    local lines = vim.split(content, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  end,
}

return M
