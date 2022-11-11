local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

describe("env/manual source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show manuals", function()
    helper.sync_start("env/manual")
    helper.sync_input({ "ls" })

    thetto.execute("move_to_list")

    assert.exists_pattern("ls(1)")
  end)
end)
