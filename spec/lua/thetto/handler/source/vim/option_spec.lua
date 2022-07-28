local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/option source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show options", function()
    vim.opt_local.buftype = "nofile"

    thetto.start("vim/option")
    helper.sync_input({ "buftype" })

    thetto.execute("move_to_list")
    assert.current_line("buftype=nofile")
  end)

  it("can toggle options", function()
    vim.opt_local.wrap = true

    thetto.start("vim/option")
    helper.sync_input({ "wrap" })

    thetto.execute("move_to_list")
    helper.search("^wrap=")

    thetto.execute("toggle")
    assert.is_false(vim.wo.wrap)
  end)
end)
