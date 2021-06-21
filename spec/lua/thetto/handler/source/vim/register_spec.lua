local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/register source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show registers", function()
    helper.set_lines([[
foo]])
    vim.cmd("normal! dw")

    thetto.start("vim/register", {opts = {insert = false}})

    thetto.execute("move_to_list")
    assert.current_line("\" foo")
  end)

end)
