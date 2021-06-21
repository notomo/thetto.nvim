local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/runtimepath source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show runtime paths", function()
    thetto.start("vim/runtimepath", {opts = {insert = false}})

    assert.exists_pattern("thetto.nvim")
  end)

  it("can execute tab_open", function()
    thetto.start("vim/runtimepath", {opts = {insert = false}})

    helper.search("thetto.nvim")
    thetto.execute("tab_open")

    assert.tab_count(2)
  end)

  it("can execute vsplit_open", function()
    thetto.start("vim/runtimepath", {opts = {insert = false}})

    helper.search("thetto.nvim")
    thetto.execute("vsplit_open")

    assert.window_count(2)
  end)

end)
