local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("file/bookmark source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show file bookmarks", function()
    local source = require("thetto/source/file/bookmark")
    source.file_path = helper.root .. "/test/_test_data/file_bookmark"
    source.default_paths = {helper.root .. "/test/_test_data/"}

    command("Thetto file/bookmark --no-insert")

    assert.exists_pattern("_test_data/file_bookmark")

    command("ThettoDo")
  end)

end)
