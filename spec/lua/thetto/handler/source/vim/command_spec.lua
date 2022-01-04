local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/command source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show global ex commands", function()
    vim.cmd("command! ThettoTest echomsg 'executed vim/command'")

    thetto.start("vim/command")

    helper.sync_input({ "ThettoTest" })
    thetto.execute("move_to_list")

    assert.exists_pattern("ThettoTest")
  end)

  it("can show buffer local ex commands", function()
    vim.cmd("command! -buffer HogeFoo echomsg 'executed vim/command'")

    thetto.start("vim/command")

    helper.sync_input({ "HogeFoo" })
    thetto.execute("move_to_list")

    assert.current_line("HogeFoo echomsg 'executed vim/command'")

    thetto.execute()
  end)
end)
