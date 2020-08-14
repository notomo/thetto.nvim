local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("vim/variable source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show variables", function()
    command("let b:hoge_foo = {}")

    command("Thetto vim/variable")

    helper.sync_input({"hoge_foo"})
    command("ThettoDo move_to_list")

    assert.exists_pattern("b:hoge_foo={}")
  end)

end)
