local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("env/variable source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show environment variables", function()
    command("Thetto env/variable --no-insert")

    helper.search("^HOME=")

    command("ThettoDo")

    assert.exists_message("HOME=.*")
  end)

end)
