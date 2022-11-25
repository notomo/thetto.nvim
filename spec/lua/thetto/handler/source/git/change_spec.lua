local helper = require("thetto.test.helper")

describe("git/change source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show changes", function()
    helper.sync_start("git/change", { opts = { insert = false }, source_opts = { commit_hash = "c458d99" } })

    assert.exists_pattern("LICENSE")
  end)
end)
