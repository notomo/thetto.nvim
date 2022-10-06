local helper = require("thetto.test.helper")

describe("env/process source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can execute kill", function()
    local sleep1 = require("thetto.lib.job").new({ "sleep", "8" }, {})
    sleep1:start()
    local sleep2 = require("thetto.lib.job").new({ "sleep", "9" }, {})
    sleep2:start()

    helper.sync_open("env/process", { opts = { insert = false } })
    helper.search("sleep 8")
    helper.sync_execute("toggle_selection")
    helper.search("sleep 9")
    helper.sync_execute("toggle_selection")

    helper.sync_execute("kill")

    vim.wait(1000, function()
      return not sleep1:is_running() and not sleep2:is_running()
    end)
    assert.is_false(sleep1:is_running())
    assert.is_false(sleep2:is_running())
  end)
end)
