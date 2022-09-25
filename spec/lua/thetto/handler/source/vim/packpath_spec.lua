local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/packpath source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show packpath", function()
    thetto.start("vim/packpath", { opts = { insert = false } })
    assert.exists_pattern("nvim/runtime")
  end)
end)
