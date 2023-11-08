local M = {}

function M.collect()
  local items = {}
  local names = vim.fn.getcompletion("*", "var")
  for _, name in ipairs(names) do
    local var
    local key = name:sub(3)
    if vim.startswith(name, "b:") then
      var = vim.b[key]
    elseif vim.startswith(name, "w:") then
      var = vim.w[key]
    elseif vim.startswith(name, "t:") then
      var = vim.t[key]
    elseif vim.startswith(name, "v:") then
      var = vim.v[key]
    else
      var = vim.g[name]
      name = "g:" .. name
    end

    if type(var) == "string" then
      var = vim.inspect(var, { newline = "\\n" })
    elseif type(var) == "table" then
      var = vim.inspect(var, { newline = " ", indent = "" })
    end

    local value = ("%s=%s"):format(name, var)
    table.insert(items, { value = value })
  end
  return items
end

M.kind_name = "vim/variable"

return M
