local M = {}

function M.root(cwd)
  return require("thetto.lib.file").find_git_root(cwd)
end

function M.exists(git_root, commit_hash, path)
  local cmd = { "git", "show", "--quiet", "--pretty=format:%h", commit_hash, "--", path }
  return require("thetto.util.job")
    .promise(cmd, {
      cwd = git_root,
      on_exit = function() end,
    })
    :next(function(output)
      return output ~= ""
    end)
end

function M.diff(git_root, bufnr, cmd)
  cmd = cmd or { "git", "--no-pager", "diff", "--date=iso" }
  return require("thetto.util.job")
    .promise(cmd, {
      cwd = git_root,
      on_exit = function() end,
    })
    :next(function(output)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      local lines = vim.split(output, "\n", { plain = true })
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

  local diff_lines = vim.split(diff, "\n", { plain = true })
  local replaced_path = "/" .. path_from_git_root
  diff_lines[1] = diff_lines[1]:gsub(path_a, replaced_path)
  diff_lines[1] = diff_lines[1]:gsub(path_b, replaced_path)
  diff_lines[3] = diff_lines[3]:gsub(path_a, replaced_path)
  diff_lines[4] = diff_lines[4]:gsub(path_b, replaced_path)

  local patch_path = vim.fn.tempname()
  local f = io.open(patch_path, "w")
  assert(f, "failed to open: " .. patch_path)
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
        assert(f, "failed to open: " .. path)
        f:write(head)
        f:close()
      end
      return path
    end)
end

function M._enable_patch(git_root, path_from_git_root, bufnr)
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
            assert(f, "failed to open: " .. working_path)
            local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            f:write(table.concat(new_lines, "\n"))
            f:close()
          end

          return require("thetto.util.job").promise(
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
          require("thetto.lib.message").warn(err)
        end)
    end,
  })
end

function M._to_path(path_or_bufnr)
  if type(path_or_bufnr) == "string" then
    return path_or_bufnr
  end
  local bufnr = path_or_bufnr
  local state = M.state()
  if not state then
    return vim.api.nvim_buf_get_name(bufnr)
  end
  return state.path
end

function M.state()
  local bufnr = vim.api.nvim_get_current_buf()
  return vim.b[bufnr].thetto_git_state
end

function M.content(git_root, path_or_bufnr, revision)
  local path = M._to_path(path_or_bufnr)
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
    :catch(function(err)
      if err:match(" does not exist in ") or err:match(" exists on disk, but not in ") then
        return ""
      end
      return require("thetto.vendor.promise").reject(err)
    end)
    :next(function(output)
      local bufnr = vim.api.nvim_create_buf(false, true)
      local lines = require("thetto.util.job.parse").output(output)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.bo[bufnr].bufhidden = "wipe"
      vim.bo[bufnr].buftype = "acwrite"
      vim.bo[bufnr].modified = false
      vim.b[bufnr].thetto_git_state = {
        path = path,
        revision = revision,
      }

      local buffer_path = "thetto-git://" .. vim.fs.joinpath(git_root, treeish)
      local old = vim.fn.bufnr(("^%s$"):format(buffer_path))
      if old ~= -1 then
        vim.api.nvim_buf_delete(old, { force = true })
      end
      vim.api.nvim_buf_set_name(bufnr, buffer_path)

      local filetype, on_detect = vim.filetype.match({ buf = bufnr, filename = path })
      if filetype then
        on_detect = on_detect or function(_) end
        vim.bo[bufnr].filetype = filetype
        on_detect(bufnr)
      end

      M._enable_patch(git_root, path_from_git_root, bufnr)

      return buffer_path
    end)
end

function M.compare(git_root, path_before, revision_before, path_after, revision_after, open)
  local before = M.content(git_root, path_before, revision_before)
  local after = M.content(git_root, path_after, revision_after)
  return require("thetto.vendor.promise").all({ before, after }):next(function(result)
    local before_buffer_path, after_buffer_path = unpack(result)

    open = open or require("thetto.lib.buffer").open_scratch_tab
    open()

    vim.cmd.edit(require("thetto.lib.file").escape(before_buffer_path))
    vim.cmd.diffthis()
    local before_winbar = vim.wo.winbar
    local before_window_id = vim.api.nvim_get_current_win()

    vim.cmd.vsplit({ args = { require("thetto.lib.file").escape(after_buffer_path) }, mods = { split = "belowright" } })
    vim.cmd.diffthis()

    local after_winbar = vim.wo.winbar
    local after_window_id = vim.api.nvim_get_current_win()

    -- to match the height of two windows
    if before_winbar == "" and after_winbar ~= "" then
      vim.wo[before_window_id].winbar = after_winbar
    elseif before_winbar ~= "" and after_winbar == "" then
      vim.wo[after_window_id].winbar = before_winbar
    end
  end)
end

function M.create_stash(git_root)
  return require("thetto.util.input")
    .promise({
      prompt = "Create stash: ",
    })
    :next(function(input)
      if not input or input == "" then
        return require("thetto.lib.message").info("invalid input to create stash")
      end
      return require("thetto.util.job").promise({ "git", "stash", "save", input }, { cwd = git_root }):next(function()
        require("thetto.lib.message").info(("Created stash: %s"):format(input))
      end)
    end)
end

return M
