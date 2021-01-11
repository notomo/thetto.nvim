local helper = require("thetto/lib/testlib/helper")

describe("process source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can execute kill", function()
    local sleep = require("thetto/lib/job").new({"sleep", "8"}, {})
    sleep:start()

    helper.sync_open("process", "--no-insert")
    helper.search("sleep 8")

    helper.sync_execute("kill")

    vim.wait(1000, function()
      return not sleep:is_running()
    end)
    assert.is_false(sleep:is_running())
  end)

end)
