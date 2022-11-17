local M = {}

function M.render_diff(bufnr, item)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "diff"
  local cmd = { "git", "--no-pager", "show", "--date=iso", item.commit_hash or item.stash_name }
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

function M.open_diff(items, f)
  local promises = {}
  for _, item in ipairs(items) do
    local bufnr = vim.api.nvim_create_buf(false, true)
    local promise = M.render_diff(bufnr, item)
    table.insert(promises, promise)
    f(bufnr)
  end
  return require("thetto.vendor.promise").all(promises)
end

function M.content(git_root, path, revision)
  if not revision then
    return require("thetto.vendor.promise").resolve(path)
  end

  local path_from_git_root = path:sub(#git_root + 2)
  local treeish = ("%s:%s"):format(revision, path_from_git_root)

  return require("thetto.util.job")
    .promise({
      "git",
      "--no-pager",
      "show",
      treeish,
    }, {
      cwd = git_root,
      on_exit = function() end,
    })
    :next(function(output)
      local bufnr = vim.api.nvim_create_buf(false, true)
      local lines = vim.split(output, "\n", true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

      local buffer_path = "thetto-git://" .. git_root .. "/" .. treeish
      local old = vim.fn.bufnr(("^%s$"):format(buffer_path))
      if old ~= -1 then
        vim.api.nvim_buf_delete(old, { force = true })
      end
      vim.api.nvim_buf_set_name(bufnr, buffer_path)

      local filetype, on_detect = vim.filetype.match({ buf = bufnr, filename = path })
      if filetype then
        on_detect = on_detect or function() end
        vim.bo[bufnr].filetype = filetype
        on_detect(bufnr)
      end

      return buffer_path
    end)
end

function M.compare(path_before, revision_before, path_after, revision_after)
  local git_root, err = require("thetto.lib.file").find_git_root()
  if err then
    return require("thetto.vendor.promise").reject(err)
  end

  local before = M.content(git_root, path_before, revision_before)
  local after = M.content(git_root, path_after, revision_after)
  return require("thetto.vendor.promise").all({ before, after }):next(function(result)
    local before_buffer_path, after_buffer_path = unpack(result)
    vim.cmd.tabedit()

    vim.cmd.edit(before_buffer_path)
    vim.cmd.diffthis()

    vim.cmd.vsplit({ args = { after_buffer_path }, mods = { split = "belowright" } })
    vim.cmd.diffthis()
  end)
end

return M
