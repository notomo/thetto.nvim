local helper = require("thetto.test.helper")

describe("git/log source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show log", function()
    helper.sync_open("git/log", { opts = { insert = false } })

    assert.exists_pattern("<notomo>")
  end)
end)
