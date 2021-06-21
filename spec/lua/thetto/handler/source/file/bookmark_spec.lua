local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("file/bookmark source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show file bookmarks", function()
    thetto.setup({
      source = {
        ["file/bookmark"] = {
          opts = {file_path = helper.path("file_bookmark"), default_paths = {helper.path()}},
        },
      },
    })

    thetto.start("file/bookmark", {opts = {insert = false}})

    assert.exists_pattern("file_bookmark")

    thetto.execute()
  end)

end)
