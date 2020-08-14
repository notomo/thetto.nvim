local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("directory/recursive source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show directories recursively", function()
    vim.api.nvim_set_current_dir("./test/_test_data")

    helper.sync_open("directory/recursive", "--no-insert")

    assert.exists_pattern("dir/")
    assert.no.exists_pattern("dir/file")
    helper.search("dir/$")

    command("ThettoDo")

    assert.current_dir(helper.root .. "/test/_test_data/dir")
  end)

  it("can show directories with depth range", function()
    vim.api.nvim_set_current_dir("./test/_test_data")

    helper.sync_open("directory/recursive", "--no-insert", "--x-max-depth=1")

    assert.no.exists_pattern("dir/depth2")
    assert.exists_pattern("dir/$")

    command("ThettoDo")
  end)

  it("can execute enter", function()
    vim.api.nvim_set_current_dir("./test/_test_data")

    helper.sync_open("directory/recursive", "--no-insert")
    helper.search("dir/$")

    command("ThettoDo enter")
    command("ThettoDo move_to_list")

    assert.exists_pattern("depth2/")
  end)

end)
