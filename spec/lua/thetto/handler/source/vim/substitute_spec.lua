local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/substitute source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show all substitute", function()
    thetto.setup({
      source = {
        ["vim/substitute"] = { opts = { commands = { hoge_to_foo = { pattern = "hoge", after = "foo" } } } },
      },
    })

    helper.set_lines([[
hoge
foo
hoge]])

    thetto.start("vim/substitute", { opts = { insert = false } })

    helper.search("hoge_to_foo")
    thetto.execute()

    assert.current_line("foo")
    assert.no.exists_pattern("hoge")
  end)

  it("can preview substitute", function()
    thetto.setup({
      source = {
        ["vim/substitute"] = { opts = { commands = { hoge_to_foo = { pattern = "hoge", after = "foo" } } } },
      },
    })
    helper.set_lines([[
hoge
foo
hoge]])

    thetto.start("vim/substitute", { opts = { insert = false, auto = "preview" } })
  end)
end)
