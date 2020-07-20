local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("file/in_dir source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show current dir files", function()
    vim.api.nvim_set_current_dir("./test/_test_data")

    command("Thetto file/in_dir --no-insert")

    assert.exists_pattern("oldfile")
    helper.search("dir")

    command("ThettoDo")

    assert.current_dir(helper.root .. "/test/_test_data/dir")

    command("Thetto file/in_dir --no-insert")

    command("ThettoDo")

    assert.file_name("file")
  end)

  it("can show files in project dir", function()
    require("thetto/target/project").root_patterns = {"0_root_pattern"}
    vim.api.nvim_set_current_dir("./test/_test_data/dir")
    command("Thetto file/in_dir --no-insert --target=project")

    command("normal! gg")
    assert.current_line("0_root_pattern/")
  end)

end)