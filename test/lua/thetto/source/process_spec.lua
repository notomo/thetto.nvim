local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("process source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can execute kill", function()
    local sleep = require("thetto/job").new({"sleep", "8"}, {})
    sleep:start()

    helper.sync_open("process", "--no-insert")
    helper.search("sleep 8")

    command("ThettoDo echo --no-quit")

    helper.sync_execute("kill")

    assert.is_false(sleep:is_running())
  end)

end)
