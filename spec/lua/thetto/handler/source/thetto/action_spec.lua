local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("thetto/action source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show actions", function()
    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line", { opts = { insert = false } })
    helper.search("test2")

    thetto.start("thetto/action", { opts = { insert = false } })
    helper.search("open")
    thetto.execute()

    assert.current_line("test2")
  end)

  it("shows error if action source is not executed in thetto buffer", function()
    helper.sync_open("thetto/action")
    assert.exists_message([[must be executed in thetto buffer]])
  end)

  it("can execute no-quit action", function()
    helper.set_lines([[
test1
]])

    thetto.start("line", { opts = { insert = false } })

    thetto.start("thetto/action", { opts = { insert = false } })
    helper.search("move_to_input")
    thetto.execute()

    assert.filetype("thetto-input")
  end)

  it("can show exnteded actions", function()
    helper.test_data:create_file(
      "Makefile",
      [[
build:
	echo 'build'
]]
    )

    thetto.start("cmd/make/target", { opts = { insert = false } })
    thetto.start("thetto/action", { opts = { insert = false } })

    assert.exists_pattern("open")
  end)
end)
