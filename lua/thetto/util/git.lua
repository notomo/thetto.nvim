local M = {}

function M.root(cwd)
  return require("thetto.lib.file").find_git_root(cwd)
end

--- @async
function M.exists(git_root, commit_hash, path)
  local cmd = { "git", "show", "--quiet", "--pretty=format:%h", commit_hash, "--", path }
  local output = require("thetto.util.job").await(cmd, {
    cwd = git_root,
    on_exit = function() end,
  })
  return output ~= ""
end

--- @async
function M.diff(git_root, bufnr, cmd)
  cmd = cmd or { "git", "--no-pager", "diff", "--date=iso" }
  local output = require("thetto.util.job").await(cmd, {
    cwd = git_root,
    on_exit = function() end,
  })
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local lines = vim.split(output, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

function M.diff_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "diff"
  return bufnr
end

--- @async
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

  return require("thetto.util.job").await({ "git", "apply", "--verbose", "--cached", patch_path }, {
    cwd = git_root,
    on_exit = function() end,
  })
end

--- @async
function M._index_content_path(git_root, path_from_git_root)
  local head = require("thetto.util.job").await({ "git", "--no-pager", "show", ":" .. path_from_git_root }, {
    cwd = git_root,
    on_exit = function() end,
  })

  local path = vim.fn.tempname()
  do
    local f = io.open(path, "w")
    assert(f, "failed to open: " .. path)
    f:write(head)
    f:close()
  end
  return path
end

function M._enable_patch(git_root, path_from_git_root, bufnr)
  local index_path, working_path
  vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
    buf = bufnr,
    callback = function()
      --- @async
      --- @return nil
      local write = function()
        index_path = M._index_content_path(git_root, path_from_git_root)

        working_path = vim.fn.tempname()
        do
          local f = io.open(working_path, "w")
          assert(f, "failed to open: " .. working_path)
          local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          f:write(table.concat(new_lines, "\n"))
          f:close()
        end

        local diff = require("thetto.util.job").await(
          { "git", "--no-pager", "diff", "--no-index", "--", index_path, working_path },
          {
            cwd = git_root,
            on_exit = function() end,
            is_err = function(code)
              return code ~= 0 and code ~= 1
            end,
          }
        )

        M._apply(git_root, diff, index_path, working_path, path_from_git_root)
        vim.bo[bufnr].modified = false
      end

      --- @async
      --- @return nil
      local run = function()
        local ok, err = pcall(write)
        if not ok then
          require("thetto.lib.message").warn(err)
        end
      end
      vim.async.run(run)
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

function M._set_name(bufnr, buffer_path)
  local old = vim.fn.bufnr(("^%s$"):format(buffer_path))
  if old ~= -1 then
    return
  end
  vim.api.nvim_buf_set_name(bufnr, buffer_path)
end

local function show(content)
  if not content.bufnr then
    vim.cmd.edit({ args = { content.buffer_path }, magic = { file = false } })
    return
  end
  vim.api.nvim_win_set_buf(0, content.bufnr)
  M._set_name(content.bufnr, content.buffer_path)
end

--- @async
function M.content(git_root, path_or_bufnr, revision, scratch_bufnr)
  local path = M._to_path(path_or_bufnr)
  if not revision then
    return {
      buffer_path = path,
    }
  end

  local path_from_git_root = path:sub(#git_root + 2)
  local treeish = ("%s:%s"):format(revision, path_from_git_root)

  local ok, output = pcall(require("thetto.util.job").await, {
    "git",
    "--no-pager",
    "show",
    treeish,
  }, {
    cwd = git_root,
    on_exit = function() end,
  })
  if not ok then
    local err = output
    if not err:match(" does not exist in ") and not err:match(" exists on disk, but not in ") then
      error(err, 0)
    end
    output = ""
  end

  local bufnr = scratch_bufnr or vim.api.nvim_create_buf(false, true)
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
  M._set_name(bufnr, buffer_path)

  local filetype, on_detect = vim.filetype.match({ buf = bufnr, filename = path })
  if filetype then
    on_detect = on_detect or function(_) end
    vim.bo[bufnr].filetype = filetype
    on_detect(bufnr)
  end

  return {
    path_from_git_root = path_from_git_root,
    bufnr = bufnr,
    buffer_path = buffer_path,
  }
end

--- @async
function M.compare(git_root, path_before, revision_before, path_after, revision_after, open)
  local result = require("thetto.lib.async").all({
    --- @async
    function()
      return M.content(git_root, path_before, revision_before)
    end,
    --- @async
    function()
      return M.content(git_root, path_after, revision_after)
    end,
  })
  local before, after = unpack(result)

  if before.bufnr then
    M._enable_patch(git_root, before.path_from_git_root, before.bufnr)
  end
  if after.bufnr then
    M._enable_patch(git_root, after.path_from_git_root, after.bufnr)
  end

  open = open or require("thetto.lib.buffer").open_scratch_tab
  open()

  show(before)
  vim.cmd.diffthis()
  local before_winbar = vim.wo.winbar
  local before_window_id = vim.api.nvim_get_current_win()

  vim.cmd.vsplit({ mods = { split = "belowright" } })
  show(after)
  vim.cmd.diffthis()

  local after_window_id = vim.api.nvim_get_current_win()
  local after_winbar = vim.wo[after_window_id][0].winbar

  -- to match the height of two windows
  if before_winbar == "" and after_winbar ~= "" then
    vim.wo[before_window_id][0].winbar = after_winbar
  elseif before_winbar ~= "" and after_winbar == "" then
    vim.wo[after_window_id][0].winbar = before_winbar
  end
end

function M.create_stash(git_root)
  --- @async
  local run = function()
    local input = require("thetto.util.input").await({
      prompt = "Create stash: ",
    })
    if not input or input == "" then
      return require("thetto.lib.message").info("invalid input to create stash")
    end

    require("thetto.util.job").await({ "git", "stash", "save", input }, { cwd = git_root })
    require("thetto.lib.message").info(("Created stash: %s"):format(input))
  end
  return vim.async.run(run)
end

return M
