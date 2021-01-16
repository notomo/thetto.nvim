local helper = require("thetto/lib/testlib/helper")

describe("git/status source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show status files", function()
    helper.new_file("test_file")

    helper.sync_open("git/status", "--no-insert")

    assert.exists_pattern("?? " .. helper.test_data_path)
  end)

end)
