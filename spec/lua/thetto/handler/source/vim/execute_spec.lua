local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/execute source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show command execute output", function()
    thetto.start("vim/execute", { source_opts = { cmd = "version" }, opts = { insert = false } })

    assert.exists_pattern("NVIM")
  end)
end)
