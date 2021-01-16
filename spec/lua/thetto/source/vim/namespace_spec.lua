local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("vim/namespace source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show namespaces", function()
    local name = "thetto_test_namespace"
    vim.api.nvim_create_namespace(name)

    command("Thetto vim/namespace --no-insert")

    assert.exists_pattern(name)
  end)

end)
