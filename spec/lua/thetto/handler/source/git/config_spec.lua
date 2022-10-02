local helper = require("thetto.lib.testlib.helper")

describe("git/config source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show config list", function()
    helper.sync_open("git/config", { opts = { insert = false } })

    assert.exists_pattern("remote.origin.url=https://github.com/notomo/thetto.nvim.git")
  end)
end)
