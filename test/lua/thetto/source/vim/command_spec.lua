local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("vim/command source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show global ex commands", function()
    command("Thetto vim/command")

    helper.sync_input({"Thetto"})
    command("ThettoDo move_to_list")

    assert.exists_pattern("Thetto")
  end)

  it("can show buffer local ex commands", function()
    command("command! -buffer HogeFoo echomsg 'executed vim/command'")

    command("Thetto vim/command")

    helper.sync_input({"HogeFoo"})
    command("ThettoDo move_to_list")

    assert.current_line("HogeFoo echomsg 'executed vim/command'")

    command("ThettoDo")
  end)

end)
