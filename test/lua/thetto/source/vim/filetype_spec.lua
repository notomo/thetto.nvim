local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("vim/filetype source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show filetypes", function()
    command("Thetto vim/filetype")
    helper.sync_input({"lua"})

    command("ThettoDo move_to_list")
    assert.current_line("lua")
  end)

end)
