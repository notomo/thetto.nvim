local M = {}

M.behaviors = {
  toggle_stage = { quit = false },
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

return require("thetto.core.kind").extend(M, "file")
