local events = {
  items_changed = "items_changed",
  source_started = "source_started",
  source_completed = "source_completed",
  source_error = "source_error",
}

local M = {
  all = events,
}

--- @param items table
--- @param all_items_count integer
--- @param pipeline_highlight fun()
function M.items_changed(items, all_items_count, pipeline_highlight)
  return events.items_changed, items, all_items_count, pipeline_highlight
end

--- @param source_name string
--- @param source_ctx table
function M.source_started(source_name, source_ctx)
  return events.source_started, source_name, source_ctx
end

--- @param item_cursor table
function M.source_completed(item_cursor)
  return events.source_completed, item_cursor
end

--- @param err string
function M.source_error(err)
  return events.source_error, err
end

return M
