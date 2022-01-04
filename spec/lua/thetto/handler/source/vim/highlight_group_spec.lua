local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/highlight_group source", function()
  before_each(helper.before_each)
  before_each(function()
    helper.before_each()
    vim.cmd("highlight! default link ThettoTestLink Comment")
    vim.cmd("highlight! ThettoTestDef guifg=#000000 gui=bold,reverse blend=50")
  end)
  after_each(function()
    helper.after_each()
    vim.cmd("highlight! link ThettoTestLink NONE")
    vim.cmd("highlight! link ThettoTestDef NONE")
    vim.cmd("highlight clear ThettoTestLink")
    vim.cmd("highlight clear ThettoTestDef")
  end)

  it("can show highlight groups", function()
    thetto.start("vim/highlight_group")
    helper.sync_input({ "ThettoTest" })

    thetto.execute("move_to_list")

    assert.exists_pattern("xxx ThettoTestLink links to Comment")
    assert.exists_pattern("xxx ThettoTestDef guifg=#000000 gui=bold,reverse blend=50")
  end)

  it("can clear highlight group", function()
    thetto.start("vim/highlight_group")
    helper.sync_input({ "ThettoTest" })

    thetto.execute("move_to_list")
    helper.search("ThettoTestDef")

    thetto.execute("delete")

    thetto.start("vim/highlight_group")
    helper.sync_input({ "ThettoTest" })
    assert.no.exists_pattern("ThettoTestDef")
  end)
end)
