local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")
local util = helper.require("thetto.util")

describe("file/recursive source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show files recursively", function()
    helper.new_directory("dir")
    helper.new_file("dir/file")

    helper.sync_open("file/recursive", { opts = { insert = false } })

    assert.exists_pattern("dir/file")
    helper.search("dir\\/file")

    thetto.execute()

    assert.file_name("file")
  end)

  it("can show files in project dir", function()
    helper.new_directory("0_root_pattern")
    helper.new_file("0_root_pattern/in_root_pattern")

    helper.sync_open("file/recursive", { opts = { insert = false, cwd = util.cwd.project({ "0_root_pattern" }) } })

    assert.exists_pattern("root_pattern/in_root_pattern")
  end)

  it("shows error if command does not exist", function()
    thetto.setup({
      source = {
        ["file/recursive"] = {
          opts = {
            get_command = function()
              return { "not_exists_cmd" }
            end,
          },
        },
      },
    })

    thetto.start("file/recursive")
    assert.exists_message("not_exists_cmd")
  end)
end)
