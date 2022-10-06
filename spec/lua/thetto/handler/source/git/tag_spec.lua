local helper = require("thetto.test.helper")

describe("git/branch source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show tags", function()
    vim.fn.system({ "git", "tag", "tag-source-test" })

    helper.sync_open("git/tag", { opts = { insert = false } })

    assert.exists_pattern("tag-source-test")
  end)

  it("can delete tag", function()
    vim.fn.system({ "git", "tag", "tag-source-test1" })
    vim.fn.system({ "git", "tag", "tag-source-test2" })

    helper.sync_open("git/tag", { opts = { insert = false } })

    helper.search("tag-source-test1")
    helper.sync_execute("toggle_selection")
    helper.search("tag-source-test2")
    helper.sync_execute("toggle_selection")
    helper.sync_execute("delete")

    helper.sync_open("git/tag", { opts = { insert = false } })
    assert.no.exists_pattern("tag-source-test1")
    assert.no.exists_pattern("tag-source-test2")
  end)
end)
