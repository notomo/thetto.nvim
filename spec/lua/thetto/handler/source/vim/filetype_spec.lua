local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

describe("vim/filetype source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show filetypes", function()
    thetto.start("vim/filetype")
    helper.sync_input({ "lua" })

    thetto.execute("move_to_list")
    assert.current_line("lua")
  end)
end)
