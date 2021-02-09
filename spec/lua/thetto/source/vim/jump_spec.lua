local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("vim/jump source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show list and jump", function()
    helper.set_lines([[
top
b
c
bottom]])
    helper.search("top")
    vim.cmd("normal! G")
    vim.cmd("normal! gg")

    command("Thetto vim/jump")
    helper.sync_input({"bottom"})
    command("ThettoDo move_to_list")

    assert.exists_pattern(":4 bottom")

    command("ThettoDo open")

    assert.current_line("bottom")
  end)

end)
