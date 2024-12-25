local helper = require("thetto.test.helper")
local assert = helper.typed_assert(assert)

describe("parse", function()
  it("joins streamed string", function()
    local concat = require("thetto.util.job.parse").concat_func()
    local got1 = concat("test1\ntes")
    local got2 = concat("t2\n")
    local got3 = concat("")

    assert.equals("test1\n", got1)
    assert.equals("test2\n", got2)
    assert.equals("", got3)
  end)

  it("returns all string if empty string is inputted", function()
    local concat = require("thetto.util.job.parse").concat_func()
    local got1 = concat("test1\ntest2")
    local got2 = concat("")

    assert.equals("test1\n", got1)
    assert.equals("test2", got2)
  end)
end)
