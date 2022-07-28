local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("line source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show current buffer lines", function()
    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line", { opts = { insert = false } })

    helper.search("test2")

    thetto.execute()

    assert.current_line("test2")
  end)

  it("can execute tab_oepn", function()
    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line", { opts = { insert = false } })

    helper.search("test2")

    thetto.execute("tab_open")

    assert.tab_count(2)
    assert.current_line("test2")
  end)

  it("can execute vsplit_open", function()
    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line", { opts = { insert = false } })

    helper.search("test2")

    thetto.execute("vsplit_open")

    assert.window_count(2)
    assert.current_line("test2")
  end)

  it("can execute open", function()
    helper.set_lines([[
test1
test2
test3]])
    vim.cmd.vsplit()
    vim.cmd.wincmd("w")
    local window = vim.api.nvim_get_current_win()

    thetto.start("line", { opts = { insert = false } })

    thetto.execute("open")

    assert.current_window(window)
  end)
end)
