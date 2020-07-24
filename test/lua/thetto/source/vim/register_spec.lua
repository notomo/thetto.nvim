local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("vim/register source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show registers", function()
    helper.set_lines([[
foo]])
    command("normal! dw")

    command("Thetto vim/register --no-insert")

    command("ThettoDo move_to_list")
    assert.current_line("\" foo")
  end)

end)
