local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/jump source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show list and jump", function()
    helper.set_lines([[
top
b
c
bottom]])
    helper.search("top")
    vim.cmd("normal! G")
    vim.cmd("normal! gg")

    thetto.start("vim/jump")
    helper.sync_input({"bottom"})
    thetto.execute("move_to_list")

    assert.exists_pattern(":4 bottom")

    thetto.execute("open")

    assert.current_line("bottom")
  end)

end)
