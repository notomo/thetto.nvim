local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("vim/buffer source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show buffers", function()
    command("edit " .. helper.root .. "/test/_test_data/dir/foo")
    command("edit " .. helper.root .. "/test/_test_data/dir/file")

    command("Thetto vim/buffer")

    command("ThettoDo move_to_list")
    assert.exists_pattern("dir/file")

    helper.search("foo")

    command("ThettoDo")
    assert.file_name("foo")
  end)

end)
