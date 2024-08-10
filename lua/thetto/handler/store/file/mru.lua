local listlib = require("thetto.lib.list")
local filelib = require("thetto.lib.file")
local pathlib = require("thetto.lib.path")
local vim = vim

local M = {}

local _opts = {}

M.opts = {
  file_path = pathlib.user_data_path("store_file_mru.txt"),
  save_events = { "VimLeavePre" },
  limit = 500,
}

function M.setup(raw_opts)
  _opts = vim.tbl_extend("force", M.opts, raw_opts or {})

  local group = vim.api.nvim_create_augroup("thetto_file_mru", {})
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = group,
    pattern = { "*" },
    callback = function(args)
      M._add(args.buf, _opts.limit)
    end,
  })
  vim.api.nvim_create_autocmd(_opts.save_events, {
    group = group,
    pattern = { "*" },
    callback = function()
      M._save(_opts.file_path)
    end,
    once = true,
  })
  vim.api.nvim_create_autocmd({ "User" }, {
    group = group,
    pattern = { "ThettoStoreSaveTrigger" },
    callback = function()
      M._save(_opts.file_path)
    end,
  })
end

local cache = setmetatable({}, {
  __index = function(tbl, key)
    local value = rawget(tbl, key)
    if value then
      return value
    end
    local paths = filelib.read_lines(_opts.file_path, 0, _opts.limit)
    tbl[key] = paths
    return rawget(tbl, key)
  end,
})

function M.data()
  return vim.iter(cache.paths):filter(M._validate):rev():totable()
end

function M._validate(path)
  return filelib.readable(path)
end

function M._add(bufnr, limit)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    return
  end

  if not M._validate(path) then
    return
  end

  local paths = cache.paths
  local removed = listlib.remove(paths, path)
  if not removed and #paths > limit then
    table.remove(paths, 1)
  end

  table.insert(paths, path)
end

function M._save(file_path)
  local paths = cache.paths
  local sliced = vim.list_slice(paths, #paths - _opts.limit, #paths)
  filelib.write_lines(file_path, sliced)
end

return M
