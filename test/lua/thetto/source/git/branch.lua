local helper = require "test.helper"
local assert = helper.assert

describe("git/branch source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show branches", function()
    helper.sync_open("git/branch", "--no-insert")

    assert.exists_pattern("master")
  end)

end)