local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe('line source', function ()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show current buffer lines", function()
    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line --no-insert")

    assert.window_count(3)
    assert.filetype("thetto")

    helper.search("test2")

    command("ThettoDo")

    assert.current_line("test2")
    assert.filetype("")
  end)

end)
