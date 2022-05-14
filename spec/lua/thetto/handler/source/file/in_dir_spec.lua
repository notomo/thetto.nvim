local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")
local util = helper.require("thetto.util")

describe("file/in_dir source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show current dir files", function()
    helper.test_data:create_file("oldfile", [[for mru test]])
    helper.test_data:create_dir("dir")
    helper.test_data:create_file("dir/file")

    thetto.start("file/in_dir", { opts = { insert = false } })

    assert.exists_pattern("oldfile")
    helper.search("dir")

    thetto.execute()

    assert.current_dir("dir")

    thetto.start("file/in_dir", { opts = { insert = false } })
    helper.search("file")

    thetto.execute()

    assert.file_name("file")
  end)

  it("can show files in project dir", function()
    helper.test_data:create_dir("0_root_pattern")
    helper.test_data:create_dir("dir")
    helper.test_data:cd("dir")

    thetto.start("file/in_dir", { opts = { insert = false, cwd = util.cwd.project({ "0_root_pattern" }) } })

    vim.cmd("normal! gg")
    assert.current_line("0_root_pattern/")
  end)

  it("can unselect by toggle_all_selection", function()
    helper.test_data:create_file("file")
    helper.test_data:create_dir("dir")

    thetto.start("file/in_dir", { opts = { insert = false } })

    thetto.execute("toggle_all_selection")
    thetto.execute("toggle_all_selection")

    thetto.execute("tab_open")
    assert.tab_count(2)
  end)
end)
