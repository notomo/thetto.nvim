local M = {}

M.opts = {}

local to_paths = function(items)
  return vim
    .iter(items)
    :map(function(item)
      return item.path
    end)
    :totable()
end

local to_git_root = require("thetto.handler.kind.git._util").to_git_root

--- @async
function M.action_toggle_stage(items)
  local bufnr = vim.api.nvim_get_current_buf()

  local will_be_stage = vim
    .iter(items)
    :filter(function(item)
      return item.index_status ~= "staged"
    end)
    :totable()
  if #will_be_stage > 0 then
    require("thetto.util.job").await({
      "git",
      "add",
      unpack(to_paths(will_be_stage)),
    }, { cwd = to_git_root(items) })
  end

  local will_be_unstage = vim
    .iter(items)
    :filter(function(item)
      return item.index_status == "staged"
    end)
    :totable()
  if #will_be_unstage > 0 then
    require("thetto.util.job").await({
      "git",
      "restore",
      "--staged",
      unpack(to_paths(will_be_unstage)),
    }, { cwd = to_git_root(items) })
  end

  return require("thetto").reload(bufnr)
end

--- @async
function M.action_discard(items)
  if #items == 0 then
    return nil
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local paths = to_paths(items)
  local git_root = to_git_root(items)

  local restore_targets = vim
    .iter(items)
    :filter(function(item)
      return item.index_status ~= "untracked"
    end)
    :totable()
  local delete_targets = vim
    .iter(items)
    :filter(function(item)
      return item.index_status == "untracked"
    end)
    :totable()
  local input = require("thetto.util.input").await({
    prompt = "Reset (y/n):\n" .. table.concat(paths, "\n"),
  })
  if input ~= "y" then
    return require("thetto.lib.message").info("Canceled discard")
  end

  if #restore_targets > 0 then
    require("thetto.util.job").await({
      "git",
      "restore",
      unpack(to_paths(restore_targets)),
    }, { cwd = git_root })
  end
  for _, path in ipairs(to_paths(delete_targets)) do
    vim.fn.delete(path, "rf")
  end

  return require("thetto").reload(bufnr)
end

--- @async
function M.action_stash(items)
  if #items == 0 then
    return nil
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local paths = to_paths(items)
  local git_root = to_git_root(items)
  require("thetto.util.job").await({
    "git",
    "stash",
    "--",
    unpack(paths),
  }, { cwd = git_root })

  require("thetto.lib.message").info("Stashed:\n" .. table.concat(paths, "\n"))
  return require("thetto").reload(bufnr)
end

M.opts.commit = {
  args = {},
}
--- @async
function M.action_commit(items, action_ctx)
  if #items == 0 then
    return nil
  end
  local git_root = to_git_root(items)
  local ok, err = pcall(require("thetto.util.job").await, { "git", "commit", unpack(action_ctx.opts.args) }, {
    cwd = git_root,
  })
  if not ok and not (err and err:match("Please supply the message")) then
    error(err, 0)
  end
end

--- @async
function M.action_commit_amend(items, action_ctx)
  return require("thetto.util.action").call(action_ctx.kind_name, "commit", items, {
    args = { "--amend" },
  })
end

--- @async
function M.action_commit_empty(items, action_ctx)
  return require("thetto.util.action").call(action_ctx.kind_name, "commit", items, {
    args = { "--allow-empty" },
  })
end

--- @async
function M.action_compare(items)
  local item = items[1]
  if not item then
    return nil
  end
  if not item.path then
    return nil
  end
  return require("thetto.util.git").compare(item.git_root, item.path, "HEAD", item.path)
end

--- @async
function M.action_compare_open(items)
  local item = items[1]
  if not item then
    return nil
  end
  if not item.path then
    return nil
  end
  return require("thetto.util.git").compare(item.git_root, item.path, "HEAD", item.path, nil, function()
    vim.cmd.only()
  end)
end

--- @async
function M.action_diff(items)
  local paths = to_paths(items)
  local git_root = to_git_root(items)
  local output = require("thetto.util.job").await({ "git", "diff", unpack(paths) }, {
    on_exit = function() end,
    cwd = git_root,
  })

  local bufnr = require("thetto.util.git").diff_buffer()
  local lines = vim.split(output, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  require("thetto.lib.buffer").open_scratch_tab()
  vim.cmd.buffer(bufnr)
end

M.opts.preview = {
  ignore_patterns = {},
}
function M.get_preview(item, action_ctx)
  if not item.path then
    return nil
  end

  if require("thetto.lib.regex").match_any(item.path, action_ctx.opts.ignore_patterns or {}) then
    return nil, { lines = { "IGNORED" } }
  end

  if item.index_status == "untracked" then
    return require("thetto.util.action").preview("file", item, action_ctx)
  end

  local bufnr = require("thetto.util.git").diff_buffer()
  local cmd = { "git", "--no-pager", "diff", "--date=iso" }
  if item.index_status == "staged" then
    table.insert(cmd, "--cached")
  end
  vim.list_extend(cmd, { "--", item.path })
  --- @async
  local render = function()
    return require("thetto.util.git").diff(item.git_root, bufnr, cmd)
  end
  return vim.async.run(render), { raw_bufnr = bufnr }
end

M.default_action = "open"

return M
