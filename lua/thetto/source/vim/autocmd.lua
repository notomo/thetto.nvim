local M = {}

local Autocmd = {}
Autocmd.__index = Autocmd

function Autocmd.new(raw)
  local autocmd = raw or {}
  return setmetatable(autocmd, Autocmd)
end

function Autocmd.string(self)
  return ("%s %s %s %s"):format(self.group, self.event, self.pattern, self.cmd)
end

function Autocmd.value(self)
  return {
    group = self.group,
    event = self.event,
    pattern = self.pattern,
    cmd = self.cmd,
    path = self.path,
    row = self.row,
  }
end

local Parser = {}
Parser.__index = Parser

function Parser.new(home)
  local parser = {}
  parser.autocmd = nil
  parser.autocmds = {}
  parser.home = home
  return setmetatable(parser, Parser)
end

function Parser.eat(self, output)
  -- ex. MyAuGroup  WinEnter
  local group, event = output:match("^(%S+)%s+(%w+)$")
  if group ~= nil and event ~= nil then
    self.autocmd = Autocmd.new()
    self.autocmd.group = group
    self.autocmd.event = event
    return
  end

  -- ex. WinEnter
  event = output:match("^(%S+)$")
  if event ~= nil then
    self.autocmd = Autocmd.new()
    self.autocmd.event = event
    self.autocmd.group = "NoneGroup"
    return
  end

  -- not supported lang=ja?
  -- ex. \tLast set from /path/to/file line 8888
  local path, row = output:match("^%s+Last%s+set%s+from%s+(%S+)%s+line%s+(%d+)")
  if path ~= nil and row ~= nil then
    self.autocmd.path = path:gsub("^~", self.home)
    self.autocmd.row = tonumber(row)
    if self.autocmd.event == nil or self.autocmd.pattern == nil or self.autocmd.cmd == nil then
      local err = ("parse error: output=%s, current=%s"):format(output, vim.inspect(self.autocmd:value()))
      error(err)
    end
    table.insert(self.autocmds, Autocmd.new(vim.deepcopy(self.autocmd)))
    return
  end

  -- ex.    *         echomsg "executed"
  local pattern, cmd = output:match("^    (%S+)%s+(.+)")
  if pattern ~= nil and cmd ~= nil then
    self.autocmd.pattern = pattern
    self.autocmd.cmd = cmd
    return
  end

  -- ex.    <buffer=8888>
  pattern = output:match("^    (%S+)")
  if pattern ~= nil then
    self.autocmd.pattern = pattern
    return
  end

  if self.autocmd.pattern ~= nil then
    cmd = output:match("^%s+(.+)")
    if cmd ~= nil then
      self.autocmd.cmd = cmd
      return
    end
    local err = ("parse error: output=%s, current=%s"):format(output, vim.inspect(self.autocmd:value()))
    error(err)
  end

  local err = ("parse error: output=%s, current=%s"):format(output, vim.inspect(self.autocmd:value()))
  error(err)
end

function M.collect(self)
  local result = vim.api.nvim_exec("verbose autocmd", true)
  local outputs = vim.split(result, "\n", true)
  table.remove(outputs, 1)

  local items = {}
  local parser = Parser.new(self.pathlib.home())
  for _, output in ipairs(outputs) do
    parser:eat(output)
  end
  for _, autocmd in ipairs(parser.autocmds) do
    table.insert(items, {
      value = autocmd:string(),
      autocmd = autocmd:value(),
      path = autocmd.path,
      row = autocmd.row,
    })
  end
  return items
end

M.kind_name = "vim/autocmd"

return M
