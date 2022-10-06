local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")
local cwd_util = helper.require("thetto.util.cwd")

describe("cmd/make/target source", function()
  before_each(function()
    helper.before_each()
    helper.test_data:create_file(
      "Makefile",
      [[
start:
	echo 'start'

TEST:=test:test

test:
	echo 'test'

	invalid:
		echo 'test'

.PHONY: test

]]
    )
    helper.test_data:create_file(
      "test.mk",
      [[
build:
	echo 2
]]
    )

    helper.test_data:create_dir("sub")
    helper.test_data:create_file(
      "sub/Makefile",
      [[
sub_test:
	echo 1
]]
    )
  end)
  after_each(helper.after_each)

  it("can show makefile targets", function()
    thetto.start("cmd/make/target", { opts = { insert = false } })

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
    helper.test_data:cd("sub")
    thetto.start("cmd/make/target", {
      opts = { insert = false, cwd = cwd_util.project({ "Makefile" }) },
    })

    assert.exists_pattern("Makefile:1 sub_test")
  end)
end)
