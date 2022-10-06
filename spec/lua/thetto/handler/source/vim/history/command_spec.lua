local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

describe("vim/history/command source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show command history", function()
    vim.fn.histadd("cmd", "8888")

    thetto.start("vim/history/command", { opts = { insert = false } })

    assert.exists_pattern("8888")
  end)
end)
