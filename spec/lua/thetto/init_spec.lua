local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

describe("thetto.start()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("wip", function()
    local p = thetto
      .start({
        collect = function()
          return {
            { value = "line1" },
            { value = "line2" },
          }
        end,
      })
      :next(function(items)
        vim.print(items)
      end)
    helper.wait(p)
  end)
end)
