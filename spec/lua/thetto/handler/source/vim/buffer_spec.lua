local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/buffer source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show buffers", function()
    helper.test_data:create_dir("dir")
    helper.test_data:create_file("dir/foo")
    helper.test_data:create_file("dir/file")

    vim.cmd.edit("dir/foo")
    vim.cmd.edit("dir/file")

    thetto.start("vim/buffer")

    thetto.execute("move_to_list")
    assert.exists_pattern("dir/file")

    helper.search("foo")

    thetto.execute()
    assert.buffer_name_tail("foo")
  end)

  it("can show terminal buffers", function()
    local bufnr = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(bufnr, "foo")

    vim.fn.termopen({ "echo", "1111" })

    thetto.start("vim/buffer", { source_opts = { buftype = "terminal" }, opts = { insert = false } })

    assert.exists_pattern("term://")
    assert.no.exists_pattern("foo")
  end)

  it("can execute tab_drop", function()
    local bufnr = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(bufnr, "foo")
    vim.cmd.tabedit()

    thetto.start("vim/buffer", { opts = { insert = false } })
    helper.search("foo")
    thetto.execute("tab_drop")

    assert.tab_count(2)

    thetto.start("vim/buffer", { opts = { insert = false } })
    helper.search("foo")
    thetto.execute("tab_drop")

    assert.tab_count(2)
  end)
end)
