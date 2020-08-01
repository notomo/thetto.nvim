local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

local _cursor = 8888

describe("thetto action completion", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show action names", function()
    helper.set_lines([[
test1]])
    command("Thetto line --no-insert")

    local result = vim.fn["thetto#complete#action"]("", "ThettoDo ", _cursor)

    assert.completion_contains(result, "open")
  end)

end)
