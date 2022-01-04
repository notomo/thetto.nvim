local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/variable source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show variables", function()
    vim.cmd("let b:hoge_foo = {}")

    thetto.start("vim/variable")

    helper.sync_input({ "hoge_foo" })
    thetto.execute("move_to_list")

    assert.exists_pattern("b:hoge_foo={}")
  end)
end)
