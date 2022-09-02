local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/help source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show help tags", function()
    thetto.start("vim/help", { opts = { insert = false } })

    assert.exists_pattern("^M$")

    thetto.execute()

    assert.exists_pattern("%*M%*")
  end)

  it("can execute tab_open", function()
    thetto.start("vim/help", { opts = { insert = false } })

    assert.exists_pattern("^M$")

    thetto.execute("tab_open")

    assert.tab_count(2)
    assert.exists_pattern("%*M%*")
  end)

  it("can execute vsplit_open", function()
    thetto.start("vim/help", { opts = { insert = false } })

    assert.exists_pattern("^M$")

    thetto.execute("vsplit_open")

    assert.window_count(2)
    assert.exists_pattern("%*M%*")
  end)
end)
