local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("vim/buffer source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show buffers", function()
    helper.new_directory("dir")
    helper.new_file("dir/foo")
    helper.new_file("dir/file")

    command("edit " .. "dir/foo")
    command("edit " .. "dir/file")

    command("Thetto vim/buffer")

    command("ThettoDo move_to_list")
    assert.exists_pattern("dir/file")

    helper.search("foo")

    command("ThettoDo")
    assert.file_name("foo")
  end)

  it("can show terminal buffers", function()
    local bufnr = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(bufnr, "foo")

    vim.fn.termopen({"echo", "1111"})

    command("Thetto vim/buffer --x-buftype=terminal --no-insert")

    assert.exists_pattern("term://")
    assert.no.exists_pattern("foo")
  end)

end)
