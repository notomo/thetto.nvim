local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("substitute source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show all substitute", function()
    require("thetto/source/substitute").commands = {hoge_to_foo = {pattern = "hoge", after = "foo"}}
    helper.set_lines([[
hoge
foo
hoge]])

    command("Thetto substitute --no-insert")

    helper.search("hoge_to_foo")
    command("ThettoDo")

    assert.current_line("foo")
    assert.no.exists_pattern("hoge")
  end)

end)
