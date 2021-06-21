local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("env/path source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show PATH directories", function()
    thetto.start("env/path", {opts = {insert = false}})

    assert.exists_pattern("/bin")
  end)

end)
