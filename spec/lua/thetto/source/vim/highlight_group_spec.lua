local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("vim/highlight_group source", function()

  before_each(helper.before_each)
  before_each(function()
    helper.before_each()
    command("highlight! default link ThettoTestLink Comment")
    command("highlight! ThettoTestDef guifg=#000000")
  end)
  after_each(function()
    helper.after_each()
    command("highlight! link ThettoTestLink NONE")
    command("highlight! link ThettoTestDef NONE")
    command("highlight clear ThettoTestLink")
    command("highlight clear ThettoTestDef")
  end)

  it("can show highlight groups", function()
    command("Thetto vim/highlight_group")
    helper.sync_input({"ThettoTest"})

    command("ThettoDo move_to_list")

    assert.exists_pattern("xxx ThettoTestLink links to Comment")
    assert.exists_pattern("xxx ThettoTestDef guifg=#000000")
  end)

  it("can clear highlight group", function()
    command("Thetto vim/highlight_group")
    helper.sync_input({"ThettoTest"})

    command("ThettoDo move_to_list")
    helper.search("ThettoTestDef")

    command("ThettoDo delete")

    command("Thetto vim/highlight_group")
    helper.sync_input({"ThettoTest"})
    assert.no.exists_pattern("ThettoTestDef")
  end)

end)
