local helper = require("thetto/lib/testlib/helper")
local thetto = helper.require("thetto")

describe("outline source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show outline", function()
    helper.new_file("Makefile", [[
test:
	echo 1
    ]])
    vim.cmd("edit Makefile")

    helper.sync_open("outline", {opts = {insert = false}})

    assert.exists_pattern("test")
  end)

end)
