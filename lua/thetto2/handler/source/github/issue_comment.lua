local M = {}

M.opts = {
  url = "",
}

function M.collect(source_ctx)
  local cmd = {
    "gh",
    "issue",
    "view",
    source_ctx.opts.url,
    "--comments",
    "--json=comments",
  }
  return require("thetto2.util.job").run(cmd, source_ctx, function(comment)
    return {
      value = comment.body:gsub("\n", " "),
      url = comment.url,
    }
  end, {
    to_outputs = function(output)
      return vim.json.decode(output, { luanil = { object = true } }).comments
    end,
  })
end

M.kind_name = "url"

return M
