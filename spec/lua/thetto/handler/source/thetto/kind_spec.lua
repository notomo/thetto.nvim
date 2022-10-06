local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

describe("thetto/kind source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show all kinds", function()
    thetto.start("thetto/kind", { opts = { insert = false } })
    thetto.execute("open")
  end)
end)
