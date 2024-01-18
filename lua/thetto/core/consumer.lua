--- @meta

--- @class ThettoConsumer
local M = {}

--- @param event_name string
--- @param ... any
function M.consume(self, event_name, ...) end

--- @param action_name string
--- @param opts table
function M.call(self, action_name, opts) end

function M.get_items(self) end

return M
