local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("directory/recursive source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show directories recursively", function()
    vim.api.nvim_set_current_dir("./test/_test_data")

    command("Thetto directory/recursive --no-insert")

    assert.exists_pattern("dir/")
    assert.not_exists_pattern("dir/file")
    helper.search("dir")

    command("ThettoDo")

    assert.current_dir(helper.root .. "/test/_test_data/dir")
  end)

end)
