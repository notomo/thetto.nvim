local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe('help source', function ()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show help tags", function()
    command("Thetto help --no-insert")

    assert.exists_pattern("$VIM")

    command("ThettoDo")

    assert.exists_pattern("%*$VIM%*")
  end)

end)
