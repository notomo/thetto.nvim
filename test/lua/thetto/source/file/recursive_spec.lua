local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("file/in_dir source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show files recursively", function()
    vim.api.nvim_set_current_dir("./test/_test_data")

    command("Thetto file/recursive --no-insert")

    assert.exists_pattern("dir/file")

    command("ThettoDo")

    assert.current_dir(helper.root .. "/test/_test_data/dir")
  end)

end)
