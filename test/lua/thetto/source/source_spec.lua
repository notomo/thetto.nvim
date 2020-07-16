local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("source source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show all sources", function()
    command("Thetto source --no-insert")

    assert.exists_pattern("source")
    assert.exists_pattern("file/mru")
    helper.search("runtimepath")

    command("ThettoDo")
    command("ThettoDo move_to_list")

    assert.exists_pattern("thetto.nvim$")
  end)

end)
