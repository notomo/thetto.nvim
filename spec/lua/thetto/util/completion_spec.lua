local helper = require("thetto.test.helper")
local completion_util = helper.require("thetto.util.completion")

describe("action_util.trigger()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("does not raise error", function()
    local promise = completion_util.trigger({
      {
        name = "test",
        collect = function()
          return {
            { value = "test1" },
            { value = "test2" },
          }
        end,
      },
    })
    helper.wait(promise)
  end)
end)
