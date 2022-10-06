local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

describe("env/variable source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show environment variables", function()
    thetto.start("env/variable", { opts = { insert = false } })

    helper.search("^HOME=")

    thetto.execute()

    assert.exists_message("HOME=.*")
  end)
end)
