local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/namespace source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show namespaces", function()
    local name = "thetto_test_namespace"
    vim.api.nvim_create_namespace(name)

    thetto.start("vim/namespace", { opts = { insert = false } })

    assert.exists_pattern(name)
  end)
end)
