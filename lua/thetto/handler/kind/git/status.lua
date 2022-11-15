local M = {}

M.behaviors = {
  toggle_stage = { quit = false },
  discard = { quit = false },
  stash = { quit = false },
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
  return require("thetto.util.input")
    .promise({
      prompt = "Reset (y/n):\n" .. table.concat(paths, "\n"),
    })
    :next(function(input)
      if input ~= "y" then
        return require("thetto.vendor.misclib.message").info("Canceled discard")
      end
      return require("thetto.util.job").promise({
        "git",
        "restore",
        unpack(paths),
      })
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

return require("thetto.core.kind").extend(M, "file")
