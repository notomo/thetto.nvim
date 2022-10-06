local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

describe("cmd/npm/script source", function()
  before_each(function()
    helper.before_each()
    helper.test_data:create_file(
      "package.json",
      [[{
  "scripts": {
    "test": "echo 1"
  }
}]]
    )
  end)
  after_each(helper.after_each)

  it("can show npm scripts", function()
    thetto.start("cmd/npm/script", { opts = { insert = false } })

    assert.exists_pattern("test")

    helper.search("test")
    thetto.execute()

    assert.tab_count(2)
  end)
end)
