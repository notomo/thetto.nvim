local M = {}

function M.collect(source_ctx)
  local cmd = { "docker", "ps", "-a", "--format={{json .}}" }
  return require("thetto2.util.job").start(cmd, source_ctx, function(output)
    local attrs = vim.json.decode(output)
    local id = attrs.ID
    local image = attrs.Image
    local command = attrs.Command
    local name = attrs.Names
    local running_for = attrs.RunningFor
    local status = attrs.Status
    local desc = ("%s %s %s (Created %s) (%s) %s"):format(id, image, command, running_for, status, name)
    return {
      value = image,
      desc = desc,
      container_id = id,
      attrs = attrs,
      column_offsets = {
        id = 0,
        value = #id + 1,
      },
    }
  end)
end

M.highlight = require("thetto2.util.highlight").columns({
  {
    group = "Comment",
    end_key = "value",
  },
})

M.kind_name = "docker/container"

return M
