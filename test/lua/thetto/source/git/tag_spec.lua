local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert

describe("git/branch source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show tags", function()
    vim.fn.system({"git", "tag", "tag-source-test"})

    helper.sync_open("git/tag", "--no-insert")

    assert.exists_pattern("tag-source-test")
  end)

  it("can delete tag", function()
    vim.fn.system({"git", "tag", "tag-source-test"})

    helper.sync_open("git/tag", "--no-insert")

    helper.search("tag-source-test")
    helper.sync_execute("delete")

    helper.sync_open("git/tag", "--no-insert")
    assert.no.exists_pattern("tag-source-test")
  end)

end)
