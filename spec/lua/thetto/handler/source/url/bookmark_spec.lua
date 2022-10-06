local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

describe("url/bookmark source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show url bookmarks", function()
    thetto.setup({
      source = {
        ["url/bookmark"] = {
          opts = { file_path = helper.path("url_bookmark"), default_lines = { "https://example.com" } },
        },
      },
    })

    thetto.start("url/bookmark", { opts = { insert = false } })

    assert.exists_pattern("https://example.com")

    thetto.execute()
  end)
end)
