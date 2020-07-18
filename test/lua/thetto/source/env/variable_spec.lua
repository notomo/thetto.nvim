local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("env/variable source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show environment variables", function()
    helper.sync_open("env/variable", "--no-insert")

    helper.search("HOME=")

    command("ThettoDo")

    assert.exists_message("HOME=.*")
  end)

end)
