local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("outline source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show outline", function()
    helper.new_file("Makefile", [[
test:
	echo 1
    ]])
    vim.api.nvim_set_current_dir(helper.test_data_dir)

    command("edit Makefile")

    helper.sync_open("outline", "--no-insert")

    assert.exists_pattern("test")
  end)

end)
