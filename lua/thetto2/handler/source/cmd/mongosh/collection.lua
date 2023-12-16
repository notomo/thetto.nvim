local M = {}

M.opts = {
  database_name = "local",
}

function M.collect(source_ctx)
  local database_name = source_ctx.opts.database_name
  local query = ([[db.getMongo().getDB("%s").getCollectionNames()]]):format(database_name)
  local cmd = { "mongosh", "--quiet", "--eval", query, "--json" }
  return require("thetto.util.job").run(cmd, source_ctx, function(name)
    return {
      value = name,
      database_name = database_name,
    }
  end, {
    to_outputs = function(output)
      return vim.json.decode(output, { luanil = { object = true } })
    end,
  })
end

M.actions = {
  action_list_children = function(items)
    local item = items[1]
    if not item then
      return
    end
    return require("thetto").start("cmd/mongosh/document", {
      source_opts = {
        database_name = item.database_name,
        collection_name = item.value,
      },
    })
  end,
}

M.kind_name = "word"

return M
