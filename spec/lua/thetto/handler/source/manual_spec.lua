local helper = require("thetto/lib/testlib/helper")
local thetto = helper.require("thetto")

describe("manual source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show manuals", function()
    helper.sync_open("manual")
    helper.sync_input({"nvim"})

    thetto.execute("move_to_list")

    assert.exists_pattern("nvim(1)")
  end)

end)