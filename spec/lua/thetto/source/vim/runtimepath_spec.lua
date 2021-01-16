local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("vim/runtimepath source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show runtime paths", function()
    command("Thetto vim/runtimepath --no-insert")

    assert.exists_pattern("thetto.nvim")
  end)

  it("can execute tab_open", function()
    command("Thetto vim/runtimepath --no-insert")

    helper.search("thetto.nvim")
    command("ThettoDo tab_open")

    assert.tab_count(2)
  end)

  it("can execute vsplit_open", function()
    command("Thetto vim/runtimepath --no-insert")

    helper.search("thetto.nvim")
    command("ThettoDo vsplit_open")

    assert.window_count(2)
  end)

end)
