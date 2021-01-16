local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("file/bookmark source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show file bookmarks", function()
    local source = require("thetto/source/file/bookmark")
    source.file_path = helper.path("file_bookmark")
    source.default_paths = {helper.path()}

    command("Thetto file/bookmark --no-insert")

    assert.exists_pattern("file_bookmark")

    command("ThettoDo")
  end)

end)
