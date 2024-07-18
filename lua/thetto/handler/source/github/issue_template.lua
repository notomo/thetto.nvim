local M = {}

local blank_item = {
  value = "(blank)",
}

function M.collect(source_ctx)
  local root_dir = vim.fs.root(source_ctx.cwd, { ".github" })
  if not root_dir then
    return { blank_item }
  end

  local issue_template_dir = vim.fs.joinpath(root_dir, ".github/ISSUE_TEMPLATE")
  local items = vim
    .iter(vim.fs.dir(issue_template_dir, {}))
    :map(function(file_name)
      if file_name == "config.yml" or file_name == "config.yaml" then
        return nil
      end

      local path = vim.fs.joinpath(issue_template_dir, file_name)
      local content = require("thetto.lib.file").read_all(path)
      if type(content) == "table" then
        require("thetto.vendor.misclib.message").warn(("failed to read template file: %s"):format(path))
        return nil
      end

      local template_name
      for line in vim.gsplit(content, "\n", { plain = true }) do
        local s = vim.fn.matchstr(line, [[\v^name:\s+"?\zs[^"]+\ze"?$]])
        if s ~= "" then
          template_name = s
        end
      end
      if not template_name then
        require("thetto.vendor.misclib.message").warn(("failed to parse template name: %s"):format(file_name))
        return nil
      end

      return {
        value = template_name,
        path = path,
        root_dir = root_dir,
      }
    end)
    :totable()
  table.insert(items, blank_item)
  return items
end

M.kind_name = "file"

M.actions = {
  action_create_issue = function(items)
    local item = items[1]
    if not item then
      return
    end

    require("thetto.lib.buffer").open_scratch_tab()

    local cmd = {
      "gh",
      "issue",
      "create",
      "--editor",
    }
    if item.path then
      table.insert(cmd, "--template=" .. item.value)
    end
    return require("thetto.vendor.misclib.job").open_terminal(cmd, {
      cwd = item.root_dir,
      env = { _THETTO = 1 }, -- HACK
    })
  end,

  default_action = "create_issue",
}

M.consumer_opts = {
  ui = { insert = false },
}

return M
