local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

describe("thetto/resume source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show source for resume", function()
    thetto.start("line", { opts = { insert = false } })
    thetto.execute("quit")

    thetto.start("thetto/source", { opts = { insert = false } })
    thetto.execute("quit")

    thetto.start("thetto/resume", { opts = { insert = false } })

    assert.exists_pattern("line")
    assert.exists_pattern("thetto/source")
  end)
end)
