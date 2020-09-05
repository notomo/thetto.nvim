local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("make/target source", function()

  before_each(function()
    helper.before_each()
    helper.new_file("Makefile", [[
start:
	echo 'start'

TEST:=test:test

test:
	echo 'test'

	invalid:
		echo 'test'

.PHONY: test

]])
    helper.new_file("test.mk", [[
build:
	echo 2
]])
  end)
  after_each(helper.after_each)

  it("can show makefile targets", function()
    command("Thetto make/target --no-insert")

    assert.exists_pattern("test")
    assert.exists_pattern("build")
    assert.no.exists_pattern("TEST")
    assert.no.exists_pattern("invalid")
    assert.no.exists_pattern(".PHONY")

    helper.search("test")
    command("ThettoDo")

    assert.tab_count(2)
  end)

end)
