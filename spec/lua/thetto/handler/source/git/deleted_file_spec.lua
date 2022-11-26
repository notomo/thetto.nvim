local helper = require("thetto.test.helper")

describe("git/deleted_file source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show deleted files", function()
    helper.sync_start("git/deleted_file", { opts = { insert = false, input_lines = { "1e3e89a" } } })

    assert.exists_pattern("1e3e89a Refactor test test/_test_data/dir/file")
  end)
end)
