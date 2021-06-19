local helper = require("thetto/lib/testlib/helper")
local thetto = helper.require("thetto")

describe("source source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show all sources", function()
    thetto.start("source", {opts = {insert = false}})

    assert.exists_pattern("source")
    assert.exists_pattern("file/mru")
    helper.search("runtimepath")

    thetto.execute()
    thetto.execute("move_to_list")

    assert.exists_pattern("thetto.nvim$")
  end)

end)
