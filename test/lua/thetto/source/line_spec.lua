local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe('line source', function ()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can shows current buffer lines", function()
    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line")

    assert.window_count(2)
    assert.exists_pattern("test2")
  end)

end)
