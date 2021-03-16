local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("vim/option source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show options", function()
    command("setlocal buftype=nofile")

    command("Thetto vim/option")
    helper.sync_input({"buftype"})

    command("ThettoDo move_to_list")
    assert.current_line("buftype=nofile")
  end)

  it("can toggle options", function()
    command("setlocal wrap")

    command("Thetto vim/option")
    helper.sync_input({"wrap"})

    command("ThettoDo move_to_list")
    helper.search("^wrap=")

    command("ThettoDo toggle")
    assert.is_false(vim.wo.wrap)
  end)

end)
