local M = {}

function M.diff(bufnr, cmd)
  local git_root, err = require("thetto.lib.file").find_git_root()
  if err then
    return require("thetto.vendor.promise").reject(err)
  end
  cmd = cmd or { "git", "--no-pager", "diff", "--date=iso" }
  return require("thetto.util.job")
    .promise(cmd, {
      cwd = git_root,
      on_exit = function() end,
    })
    :next(function(output)
      local lines = vim.split(output, "\n", true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end)
end

function M.diff_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "diff"
  return bufnr
end

function M._apply(git_root, diff, path_a, path_b, path_from_git_root)
  if diff == "" then
    return
  end

  local diff_lines = vim.split(diff, "\n", true)
  local replaced_path = "/" .. path_from_git_root
  diff_lines[1] = diff_lines[1]:gsub(path_a, replaced_path)
  diff_lines[1] = diff_lines[1]:gsub(path_b, replaced_path)
  diff_lines[3] = diff_lines[3]:gsub(path_a, replaced_path)
  diff_lines[4] = diff_lines[4]:gsub(path_b, replaced_path)

  local patch_path = vim.fn.tempname()
  local f = io.open(patch_path, "w")
  f:write(table.concat(diff_lines, "\n") .. "\n")
  f:close()

  return require("thetto.util.job").promise({ "git", "apply", "--verbose", "--cached", patch_path }, {
    cwd = git_root,
    on_exit = function() end,
  })
end

function M._index_content_path(git_root, path_from_git_root)
  return require("thetto.util.job")
    .promise({ "git", "--no-pager", "show", ":" .. path_from_git_root }, {
      cwd = git_root,
      on_exit = function() end,
    })
    :next(function(head)
      local path = vim.fn.tempname()
      do
        local f = io.open(path, "w")
        f:write(head)
        f:close()
      end
      return path
    end)
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
      vim.bo[bufnr].bufhidden = "wipe"
      vim.bo[bufnr].buftype = "acwrite"
      vim.bo[bufnr].modified = false

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

      local index_path, working_path
      vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
        buffer = bufnr,
        callback = function()
          M._index_content_path(git_root, path_from_git_root)
            :next(function(index_content_path)
              index_path = index_content_path

              working_path = vim.fn.tempname()
              do
                local f = io.open(working_path, "w")
                local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                f:write(table.concat(new_lines, "\n"))
                f:close()
              end

              return
                require("thetto.util.job").promise(
                { "git", "--no-pager", "diff", "--no-index", "--", index_path, working_path },
                {
                  cwd = git_root,
                  on_exit = function() end,
                  is_err = function(code)
                    return code ~= 0 and code ~= 1
                  end,
                }
              )
            end)
            :next(function(diff)
              return M._apply(git_root, diff, index_path, working_path, path_from_git_root)
            end)
            :next(function()
              vim.bo[bufnr].modified = false
            end)
            :catch(function(err)
              require("thetto.vendor.misclib.message").warn(err)
            end)
        end,
      })

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
    require("thetto.lib.buffer").open_scratch_tab()

    vim.cmd.edit(before_buffer_path)
    vim.cmd.diffthis()

    vim.cmd.vsplit({ args = { after_buffer_path }, mods = { split = "belowright" } })
    vim.cmd.diffthis()
  end)
end

return M
