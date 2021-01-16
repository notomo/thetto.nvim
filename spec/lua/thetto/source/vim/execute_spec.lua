local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("vim/execute source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show command execute output", function()
    command("Thetto vim/execute --x-cmd=version --no-insert")

    assert.exists_pattern("NVIM")
  end)

end)
