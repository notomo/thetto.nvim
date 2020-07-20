local helper = require "test.helper"
local assert = helper.assert
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

    command("ThettoDo")
  end)

end)
