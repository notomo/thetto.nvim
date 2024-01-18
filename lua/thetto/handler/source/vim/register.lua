local M = {}

-- :help registers
local names = {
  '"',
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "-",
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z",
  ":",
  ".",
  "%",
  "#",
  "=",
  "*",
  "+",
  "_",
  "/",
}

function M.collect()
  return vim
    .iter(names)
    :map(function(name)
      local register = vim.fn.getreg(name)
      if register == "" then
        return
      end
      local value = ("%s %s"):format(name, register:gsub("\n", "\\n"))
      return { value = value }
    end)
    :totable()
end

M.kind_name = "word"

return M
