local helper = require("thetto/lib/testlib/helper")

describe("git/branch source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show branches", function()
    helper.sync_open("git/branch", "--no-insert")

    assert.exists_pattern("master")
  end)

  it("can show all branches", function()
    helper.sync_open("git/branch", "--no-insert", "--x-all")

    assert.exists_pattern("origin/master")
  end)

end)
