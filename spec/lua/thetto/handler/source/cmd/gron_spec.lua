local helper = require("thetto/lib/testlib/helper")
local thetto = helper.require("thetto")

describe("cmd/gron source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show gron output", function()
    helper.new_file("test.json", [[
{
  "hoge": "foo",
  "bar": "baz"
}]])
    vim.cmd("edit test.json")

    helper.sync_open("cmd/gron", {opts = {insert = false}})

    helper.search("baz")
    thetto.execute("open")

    assert.current_line([[  "bar": "baz"]])
  end)

end)
