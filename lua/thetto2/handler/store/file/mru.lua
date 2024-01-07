local listlib = require("thetto2.lib.list")
local filelib = require("thetto2.lib.file")
local pathlib = require("thetto2.lib.path")
local vim = vim

local M = {}

local _paths = {}

M.opts = {
  file_path = pathlib.user_data_path("store_file_mru.txt"),
  save_events = { "QuitPre" },
  limit = 500,
}

function M.start(opts)
  opts = vim.tbl_extend("force", M.opts, opts or {})

  local paths = filelib.read_lines(opts.file_path, 0, opts.limit)
  _paths = vim.tbl_filter(M.validate, paths)

  local group = vim.api.nvim_create_augroup("thetto_file_mru", {})
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = group,
    pattern = { "*" },
    callback = function(args)
      M.add(args.buf, opts.limit)
    end,
  })
  vim.api.nvim_create_autocmd(opts.save_events, {
    group = group,
    pattern = { "*" },
    callback = function()
      M.save(opts.file_path)
    end,
    once = true,
  })
end

function M.data()
  return vim.iter(_paths):rev():totable()
end

function M.validate(path)
  return filelib.readable(path)
end

function M.add(bufnr, limit)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    return
  end

  if not M.validate(path) then
    return
  end

  local removed = listlib.remove(_paths, path)
  if not removed and #_paths > limit then
    table.remove(_paths, 1)
  end

  table.insert(_paths, path)
end

function M.save(file_path)
  filelib.write_lines(file_path, _paths)
end

return M
