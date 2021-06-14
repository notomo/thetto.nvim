local helper = require("thetto/lib/testlib/helper")
local thetto = helper.require("thetto")

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

    helper.new_directory("sub")
    helper.new_file("sub/Makefile", [[
sub_test:
	echo 1
]])
  end)
  after_each(helper.after_each)

  it("can show makefile targets", function()
    thetto.start("make/target", {opts = {insert = false}})

    assert.exists_pattern("Makefile:6 test")
    assert.exists_pattern("test.mk:1 build")
    assert.no.exists_pattern("TEST")
    assert.no.exists_pattern("invalid")
    assert.no.exists_pattern(".PHONY")

    helper.search("test")
    thetto.execute()

    assert.tab_count(2)
  end)

  it("can use the nearest upward Makefile", function()
    helper.cd("sub")
    thetto.start("make/target", {
      opts = {insert = false, target = "upward", target_patterns = {"Makefile"}},
    })

    assert.exists_pattern("Makefile:1 sub_test")
  end)

end)
