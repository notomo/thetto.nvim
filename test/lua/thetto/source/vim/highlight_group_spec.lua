local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("vim/highlight_group source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show highlight groups", function()
    -- NOTICE: side effect
    -- How to delete the highlight groups completely?
    command("highlight default link ThettoTestLink Comment")
    command("highlight ThettoTestDef guifg=#000000")

    command("Thetto vim/highlight_group")
    helper.sync_input({"ThettoTest"})

    command("ThettoDo move_to_list")

    assert.exists_pattern("xxx ThettoTestLink links to Comment")
    assert.exists_pattern("xxx ThettoTestDef guifg=#000000")
  end)

end)
