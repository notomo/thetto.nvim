local M = {}

M.opts = {}

M.behaviors = {
  toggle_stage = { quit = false },
  discard = { quit = false },
  stash = { quit = false },
  compare = { quit = false },
  diff = { quit = false },
}

local to_paths = function(items)
  return vim.tbl_map(function(item)
    return item.path
  end, items)
end

function M.action_toggle_stage(items)
  local promises = {}

  local will_be_stage = vim.tbl_filter(function(item)
    return item.index_status ~= "staged"
  end, items)
  if #will_be_stage > 0 then
    local stage = require("thetto.util.job").promise({
      "git",
      "add",
      unpack(to_paths(will_be_stage)),
    })
    table.insert(promises, stage)
  end

  local will_be_unstage = vim.tbl_filter(function(item)
    return item.index_status == "staged"
  end, items)
  if #will_be_unstage > 0 then
    local unstage = require("thetto.util.job").promise({
      "git",
      "restore",
      "--staged",
      unpack(to_paths(will_be_unstage)),
    })
    table.insert(promises, unstage)
  end

  local bufnr = vim.api.nvim_get_current_buf()
  return require("thetto.vendor.promise").all(promises):next(function()
    return require("thetto.command").reload(bufnr)
  end)
end

function M.action_discard(items)
  if #items == 0 then
    return nil
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local paths = to_paths(items)

  local restore_targets = vim.tbl_filter(function(item)
    return item.index_status ~= "untracked"
  end, items)
  local delete_targets = vim.tbl_filter(function(item)
    return item.index_status == "untracked"
  end, items)
  return require("thetto.util.input")
    .promise({
      prompt = "Reset (y/n):\n" .. table.concat(paths, "\n"),
    })
    :next(function(input)
      if input ~= "y" then
        return require("thetto.vendor.misclib.message").info("Canceled discard")
      end
      local promises = {}
      if #restore_targets > 0 then
        local restore = require("thetto.util.job").promise({
          "git",
          "restore",
          unpack(to_paths(restore_targets)),
        })
        table.insert(promises, restore)
      end
      for _, path in ipairs(to_paths(delete_targets)) do
        vim.fn.delete(path, "rf")
      end
      return require("thetto.vendor.promise").all(promises)
    end)
    :next(function()
      return require("thetto.command").reload(bufnr)
    end)
end

function M.action_stash(items)
  if #items == 0 then
    return nil
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local paths = to_paths(items)
  return require("thetto.util.job")
    .promise({
      "git",
      "stash",
      "--",
      unpack(paths),
    })
    :next(function()
      require("thetto.vendor.misclib.message").info("Stashed:\n" .. table.concat(paths, "\n"))
      return require("thetto.command").reload(bufnr)
    end)
end

M.opts.commit = {
  args = {},
}
function M.action_commit(_, action_ctx)
  return require("thetto.util.job").promise({ "git", "commit", unpack(action_ctx.opts.args) }):catch(function(err)
    if err and err:match("Please supply the message") then
      return
    end
    return require("thetto.vendor.promise").reject(err)
  end)
end

function M.action_commit_amend(items, action_ctx, ctx)
  return require("thetto.util.action").call(action_ctx.kind_name, "commit", items, ctx, {
    args = { "--amend" },
  })
end

function M.action_compare(items)
  local item = items[1]
  if not item then
    return nil
  end
  return require("thetto.util.git").compare(item.path, "HEAD", item.path)
end

function M.action_diff(items)
  local paths = to_paths(items)
  return require("thetto.util.job")
    .promise({ "git", "diff", unpack(paths) }, {
      on_exit = function() end,
    })
    :next(function(output)
      local bufnr = require("thetto.util.git").diff_buffer()
      local lines = vim.split(output, "\n", true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      require("thetto.lib.buffer").open_scratch_tab()
      vim.cmd.buffer(bufnr)
    end)
end

return require("thetto.core.kind").extend(M, "file")
