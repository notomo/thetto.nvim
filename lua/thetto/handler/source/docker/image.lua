local M = {}

function M.collect(_, source_ctx)
  local cmd = { "docker", "images", "-f=dangling=false", "--format={{json .}}" }
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local attrs = vim.json.decode(output)
    local id = attrs.ID
    local repository = attrs.Repository
    local tag = attrs.Tag
    local size = attrs.Size
    local created_since = attrs.CreatedSince
    local name = ("%s:%s"):format(repository, tag)
    local desc = ("%s %s %s %s"):format(id, name, size, created_since)
    return {
      value = name,
      desc = desc,
      image_id = id,
      attrs = attrs,
      column_offsets = {
        id = 0,
        value = #id + 1,
        size = #id + 1 + #name + 1,
        created_since = #id + 1 + #name + #size + 1,
      },
    }
  end)
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    end_key = "value",
  },
  {
    group = "Conditional",
    start_key = "size",
    end_key = "created_since",
  },
  {
    group = "Comment",
    start_key = "created_since",
  },
})

M.kind_name = "docker/image"

return M
