local events = {
  items_changed = "items_changed",
  source_started = "source_started",
  source_completed = "source_completed",
  source_error = "source_error",
}

local M = {
  all = events,
}

function M.items_changed(items, all_items_count)
  return events.items_changed, items, all_items_count
end

function M.source_started(source_name)
  return events.source_started, source_name
end

function M.source_completed(item_cursor)
  return events.source_completed, item_cursor
end

function M.source_error(err)
  return events.source_error, err
end

return M
