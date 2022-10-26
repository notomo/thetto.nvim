local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

describe("alter source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show alternative readable files", function()
    thetto.setup({ source = { ["file/alter"] = { opts = { pattern_groups = { { "%_test.lua", "%.lua" } } } } } })

    helper.test_data:create_file("file.lua")
    helper.test_data:create_file("file_test.lua")
    vim.cmd.edit("file.lua")

    helper.sync_start("file/alter", { opts = { insert = false, immediately = true } })

    assert.buffer_name_tail("file_test.lua")
  end)

  it("can show alternative files including new files", function()
    thetto.setup({
      source = { ["file/alter"] = { opts = { pattern_groups = { { "%/from/%_test.lua", "%/to/%.lua" } } } } },
    })

    helper.test_data:create_dir("from")
    helper.test_data:create_dir("from/dir")
    helper.test_data:create_file("from/file_test.lua")
    vim.cmd.edit("./from/file_test.lua")

    helper.sync_start("file/alter", {
      source_opts = { allow_new = true },
      opts = { insert = false, immediately = true },
    })
    vim.cmd.write({ mods = { silent = true, emsg_silent = true } })

    assert.buffer_name_tail("file.lua")
    assert.dir_name("to")
  end)
end)
