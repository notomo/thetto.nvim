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
    helper.search("dir")

    command("ThettoDo")

    assert.current_dir(helper.root .. "/test/_test_data/dir")
  end)

  it("can show files in project dir", function()
    require("thetto/target/project").root_patterns = {"0_root_pattern"}
    vim.api.nvim_set_current_dir("./test/_test_data/dir")
    command("Thetto file/recursive --no-insert --target=project")

    assert.exists_pattern("root_pattern/in_root_pattern")
  end)

end)
