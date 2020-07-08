local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe('thetto', function ()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can move to filter", function()
    command("Thetto line --no-insert")

    assert.window_count(3)
    assert.filetype("thetto")

    command("ThettoDo move_to_filter")

    assert.filetype("thetto-filter")
  end)

  it("can move to list", function()
    command("Thetto line")

    assert.window_count(3)
    assert.filetype("thetto-filter")

    command("ThettoDo move_to_list")

    assert.filetype("thetto")
  end)

end)
