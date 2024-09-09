local helper = require("thetto.test.helper")
local action_util = helper.require("thetto.util.action")
local assert = helper.typed_assert(assert)

describe("action_util.grouping()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("groups items by kind_name", function()
    local got = action_util.grouping({
      { value = "test1", kind_name = "file" },
      { value = "test2", kind_name = "file" },
      { value = "test3", kind_name = "word" },
    })

    assert.same({
      { value = "test1", kind_name = "file" },
      { value = "test2", kind_name = "file" },
    }, got[1].items)

    assert.same({
      { value = "test3", kind_name = "word" },
    }, got[2].items)
  end)

  it("can include actions by option", function()
    local called = false
    local got = action_util.grouping({
      { value = "test1", kind_name = "file" },
      { value = "test2", kind_name = "file" },
    }, {
      actions = {
        action_test = function()
          called = true
        end,
        default_action = "test",
      },
    })

    got[1].action(got[1].items, {})

    assert.is_true(called)
  end)
end)
