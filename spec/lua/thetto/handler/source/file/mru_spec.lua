local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("file/mru source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show mru files", function()
    helper.new_file("oldfile")
    vim.cmd("edit oldfile")

    thetto.start("file/mru", {opts = {insert = false}})

    helper.search("oldfile")
    thetto.execute()

    assert.file_name("oldfile")
  end)

  it("can execute directory_open", function()
    helper.new_file("oldfile")
    vim.cmd("edit oldfile")

    thetto.start("file/mru", {opts = {insert = false}})

    helper.search("oldfile")
    thetto.execute("directory_open")

    assert.current_dir("")
  end)

end)
