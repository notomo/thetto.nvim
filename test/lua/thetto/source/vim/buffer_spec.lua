local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("vim/buffer source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show buffers", function()
    helper.new_directory("dir")
    helper.new_file("dir/foo")
    helper.new_file("dir/file")

    command("edit " .. "dir/foo")
    command("edit " .. "dir/file")

    command("Thetto vim/buffer")

    command("ThettoDo move_to_list")
    assert.exists_pattern("dir/file")

    helper.search("foo")

    command("ThettoDo")
    assert.file_name("foo")
  end)

end)
