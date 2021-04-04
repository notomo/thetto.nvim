local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("lua/luarocks source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show luarocks packages", function()
    helper.sync_open("lua/luarocks")
    helper.sync_input({"vusted"})

    command("ThettoDo move_to_list")
    assert.exists_pattern("vusted")
  end)

end)
