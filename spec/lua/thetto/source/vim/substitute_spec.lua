local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("vim/substitute source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show all substitute", function()
    require("thetto/source/vim/substitute").commands = {
      hoge_to_foo = {pattern = "hoge", after = "foo"},
    }
    helper.set_lines([[
hoge
foo
hoge]])

    command("Thetto vim/substitute --no-insert")

    helper.search("hoge_to_foo")
    command("ThettoDo")

    assert.current_line("foo")
    assert.no.exists_pattern("hoge")
  end)

  it("can preview substitute", function()
    require("thetto/source/vim/substitute").commands = {
      hoge_to_foo = {pattern = "hoge", after = "foo"},
    }
    helper.set_lines([[
hoge
foo
hoge]])

    command("Thetto vim/substitute --no-insert --auto=preview")
  end)

end)
