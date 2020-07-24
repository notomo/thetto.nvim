local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("file/mru source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show mru files", function()
    command("edit " .. helper.root .. "/test/_test_data/oldfile")

    command("Thetto file/mru --no-insert")

    helper.search("oldfile")
    command("ThettoDo")

    assert.file_name("oldfile")
  end)

  it("can execute directory_open", function()
    command("edit " .. helper.root .. "/test/_test_data/oldfile")

    command("Thetto file/mru --no-insert")

    helper.search("oldfile")
    command("ThettoDo directory_open")

    assert.current_dir(helper.root .. "/test/_test_data")
  end)

end)
