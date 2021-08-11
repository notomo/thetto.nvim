local M = {}

local iso_8601_format = "%Y-%m-%dT%H:%M:%SZ"

function M.elapsed_seconds_for_iso_8601(s, e)
  local start_seconds = vim.fn.strptime(iso_8601_format, s)
  local end_seconds = vim.fn.strptime(iso_8601_format, e)
  return end_seconds - start_seconds
end

function M.readable(elapsed_seconds)
  if elapsed_seconds < 60 then
    return vim.fn.strftime("%Ss", elapsed_seconds)
  end

  local minutes = elapsed_seconds / 60.0
  if minutes < 60 then
    return vim.fn.strftime("%Mm%Ss", elapsed_seconds)
  end

  local hours = minutes / 60.0
  return ("%02dh%s"):format(hours, vim.fn.strftime("%Mm%Ss", elapsed_seconds))
end

return M
