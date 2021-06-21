local helper = require("thetto.lib.testlib.helper")

describe("cmd/ctags source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show ctags output", function()
    helper.new_file("Makefile", [[
test:
	echo 1
    ]])
    vim.cmd("edit Makefile")

    helper.sync_open("cmd/ctags", {opts = {insert = false}})

    assert.exists_pattern("test")
  end)

end)
