local M = {}

M.opts = {}

function M.collect(source_ctx)
  local cmd = { "mongosh", "--quiet", "--eval", "db.getMongo().getDBNames()", "--json" }
  return require("thetto.util.job").run(cmd, source_ctx, function(name)
    return {
      value = name,
    }
  end, {
    to_outputs = function(output)
      return vim.json.decode(output, { luanil = { object = true } })
    end,
  })
end

M.kind_name = "word"

M.actions = {
  action_list_children = function(items)
    local item = items[1]
    if not item then
      return
    end
    return require("thetto").start("cmd/mongosh/collection", {
      source_opts = { database_name = item.value },
    })
  end,
}

return M
