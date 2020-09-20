local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("alter source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show alternative readable files", function()
    require("thetto/source/file/alter").opts.pattern_groups = {{"%_test.lua", "%.lua"}}

    helper.new_file("file.lua")
    helper.new_file("file_test.lua")
    command("edit file.lua")

    command("Thetto file/alter --no-insert --immediately")

    assert.file_name("file_test.lua")
  end)

  it("can show alternative files including new files", function()
    require("thetto/source/file/alter").opts.pattern_groups = {{"%_test.lua", "%.lua"}}

    helper.new_file("file_test.lua")
    command("edit file_test.lua")

    command("Thetto file/alter --no-insert --x-allow-new --immediately")

    assert.file_name("file.lua")
  end)

end)
