local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("gron source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show gron output", function()
    helper.new_file("test.json", [[
{
  "hoge": "foo",
  "bar": "baz"
}]])
    command("edit test.json")

    helper.sync_open("gron", "--no-insert")

    helper.search("baz")
    command("ThettoDo open")

    assert.current_line([[  "bar": "baz"]])
  end)

end)
