local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("alter source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show alternative readable files", function()
    thetto.setup({ source = { ["file/alter"] = { opts = { pattern_groups = { { "%_test.lua", "%.lua" } } } } } })

    helper.test_data:create_file("file.lua")
    helper.test_data:create_file("file_test.lua")
    vim.cmd("edit file.lua")

    thetto.start("file/alter", { opts = { insert = false, immediately = true } })

    assert.file_name("file_test.lua")
  end)

  it("can show alternative files including new files", function()
    thetto.setup({
      source = { ["file/alter"] = { opts = { pattern_groups = { { "%/from/%_test.lua", "%/to/%.lua" } } } } },
    })

    helper.test_data:create_dir("from")
    helper.test_data:create_dir("from/dir")
    helper.test_data:create_file("from/file_test.lua")
    vim.cmd("edit ./from/file_test.lua")

    thetto.start("file/alter", {
      source_opts = { allow_new = true },
      opts = { insert = false, immediately = true },
    })
    vim.cmd("silent! write")

    assert.file_name("file.lua")
    assert.dir_name("to")
  end)
end)
