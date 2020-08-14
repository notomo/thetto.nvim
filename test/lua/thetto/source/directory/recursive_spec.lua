local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("directory/recursive source", function()

  before_each(function()
    helper.before_each()
    helper.new_directory("dir")
    helper.new_directory("dir/depth2")
    helper.new_file("dir/file")
  end)

  after_each(helper.after_each)

  it("can show directories recursively", function()
    helper.sync_open("directory/recursive", "--no-insert")

    assert.exists_pattern("dir/")
    assert.no.exists_pattern("dir/file")
    helper.search("dir/$")

    command("ThettoDo")

    assert.current_dir("dir")
  end)

  it("can show directories with depth range", function()
    helper.sync_open("directory/recursive", "--no-insert", "--x-max-depth=1")

    assert.no.exists_pattern("dir/depth2")
    assert.exists_pattern("dir/$")

    command("ThettoDo")
  end)

  it("can execute enter", function()
    helper.sync_open("directory/recursive", "--no-insert")
    helper.search("dir/$")

    command("ThettoDo enter")
    command("ThettoDo move_to_list")

    assert.exists_pattern("depth2/")
  end)

end)
