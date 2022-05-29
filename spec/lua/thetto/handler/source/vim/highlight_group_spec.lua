local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/highlight_group source", function()
  before_each(helper.before_each)
  before_each(function()
    helper.before_each()
    vim.api.nvim_set_hl(0, "ThettoTestLink", { default = true, link = "Comment" })
    vim.api.nvim_set_hl(0, "ThettoTestDef", { fg = "#000000", bold = true, reverse = true, blend = 50 })
  end)
  after_each(helper.after_each)

  it("can show highlight groups", function()
    thetto.start("vim/highlight_group")
    helper.sync_input({ "ThettoTest" })

    thetto.execute("move_to_list")

    assert.exists_pattern("xxx ThettoTestLink links to Comment")
    assert.exists_pattern("xxx ThettoTestDef guifg=#000000 gui=bold,reverse cterm=bold,reverse blend=50")
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
