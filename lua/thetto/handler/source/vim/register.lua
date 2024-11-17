local vim = vim

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
      return {
        value = value,
        register_name = name,
      }
    end)
    :totable()
end

M.kind_name = "word"

local readonly_registers = { ".", "%", ":" }

M.actions = {
  action_delete = function(items)
    vim
      .iter(items)
      :filter(function(item)
        return not vim.tbl_contains(readonly_registers, item.register_name) and item.register_name ~= "#"
      end)
      :each(function(item)
        vim.fn.setreg(item.register_name, "")
      end)
  end,

  action_execute = function(items)
    for _, item in ipairs(items) do
      vim.cmd.normal({ args = { "@" .. item.register_name }, bang = true })
    end
  end,

  action_edit = function(items)
    local item = items[1]
    if not item then
      return
    end
    if vim.tbl_contains(readonly_registers, item.register_name) then
      return require("thetto.lib.message").info(("%s is readonly"):format(item.register_name))
    end

    return require("thetto.util.input")
      .promise({
        prompt = "Edit register: ",
        default = vim.fn.getreg(item.register_name):gsub("\n", "\\n"),
      })
      :next(function(new_value)
        if not new_value then
          return require("thetto.lib.message").info("Canceled")
        end
        vim.fn.setreg(item.register_name, new_value)
      end)
  end,
}

return M
