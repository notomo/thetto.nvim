local listlib = require("thetto.lib.list")
local filelib = require("thetto.lib.file")
local pathlib = require("thetto.lib.path")
local vim = vim

local M = {}

local _paths = {}
local _opts = {}

M.opts = {
  file_path = pathlib.user_data_path("store_file_mru.txt"),
  save_events = { "QuitPre" },
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
end

function M.data()
  local paths = M._data()
  vim.list_extend(paths, _paths)
  return vim.iter(paths):rev():totable()
end

function M._data()
  local paths = filelib.read_lines(_opts.file_path, 0, _opts.limit)
  return vim.tbl_filter(M._validate, paths)
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

  local removed = listlib.remove(_paths, path)
  if not removed and #_paths > limit then
    table.remove(_paths, 1)
  end

  table.insert(_paths, path)
end

function M._save(file_path)
  local paths = M._data()
  for _, path in ipairs(_paths) do
    listlib.remove(paths, path)
  end
  vim.list_extend(paths, _paths)
  paths = vim.list_slice(paths, #paths - _opts.limit, #paths)

  filelib.write_lines(file_path, paths)
end

return M
