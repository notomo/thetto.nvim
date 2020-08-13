local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("env/path source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show PATH directories", function()
    command("Thetto env/path --no-insert")

    assert.exists_pattern("/bin")

    command("ThettoDo")

    assert.no.current_dir(helper.root)
  end)

end)
