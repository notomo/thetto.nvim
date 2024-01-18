local pathlib = require("thetto.lib.path")
local filelib = require("thetto.lib.file")

local M = {}

local char_to_hex = function(c)
  return ("%%%02X"):format(c:byte())
end

local encode = function(url)
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w _%%%-%.~/:%?@=&#])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

M.opts = { file_path = nil, default_lines = {} }

function M.collect(source_ctx)
  local file_path = source_ctx.opts.file_path or pathlib.user_data_path("url_bookmark.txt")
  if filelib.create_if_need(file_path) then
    local f = io.open(file_path, "w")
    for _, line in ipairs(source_ctx.opts.default_lines) do
      f:write(line .. "\n")
    end
    f:close()
  end

  local items = {}
  local f = io.open(file_path, "r")
  local i = 1
  for line in f:lines() do
    local url = encode(vim.fn.reverse(vim.split(line, "\t", { plain = true }))[1])
    table.insert(items, {
      value = line,
      path = file_path,
      row = i,
      url = url,
    })
    i = i + 1
  end
  f:close()

  return items
end

M.kind_name = "file"

M.actions = {
  opts = { yank = { key = "url" } },

  action_open_url = function(items)
    return require("thetto.util.action").call("url", "open_browser", items)
  end,

  default_action = "open_url",
}

return M
