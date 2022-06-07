local OutputBuffer = {}
OutputBuffer.__index = OutputBuffer

function OutputBuffer.new()
  local tbl = { _incompleted = "" }
  return setmetatable(tbl, OutputBuffer)
end

function OutputBuffer.append(self, data)
  local head_index = data:find("\n")
  if not head_index then
    return
  end

  local head = data:sub(1, head_index - 1)
  local completed = self._incompleted .. head

  self._incompleted = data:sub(head_index + 1)

  return completed
end

function OutputBuffer.pop(self)
  return self:append("\n")
end

return OutputBuffer
