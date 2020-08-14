local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("vim/help source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show help tags", function()
    command("Thetto vim/help --no-insert")

    assert.exists_pattern("$VIM")

    command("ThettoDo")

    assert.exists_pattern("%*$VIM%*")
  end)

  it("can execute tab_open", function()
    command("Thetto vim/help --no-insert")

    assert.exists_pattern("$VIM")

    command("ThettoDo tab_open")

    assert.tab_count(2)
    assert.exists_pattern("%*$VIM%*")
  end)

  it("can execute vsplit_open", function()
    command("Thetto vim/help --no-insert")

    assert.exists_pattern("$VIM")

    command("ThettoDo vsplit_open")

    assert.window_count(2)
    assert.exists_pattern("%*$VIM%*")
  end)

end)
