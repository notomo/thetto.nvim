local helper = require("thetto.lib.testlib.helper")

describe("thetto.core.sorter", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  for _, c in ipairs({
    { items = {}, names = { "length" }, expected = {} },

    {
      items = { { value = "bbb" }, { value = "b" } },
      names = { "length" },
      expected = { { value = "b" }, { value = "bbb" } },
    },

    {
      items = {
        { value = "bbb", row = 2 },
        { value = "b", row = 2 },
        { value = "a", row = 1 },
        { value = "aaa", row = 1 },
      },
      names = { "row", "-length" },
      expected = {
        { value = "aaa", row = 1 },
        { value = "a", row = 1 },
        { value = "bbb", row = 2 },
        { value = "b", row = 2 },
      },
    },
  }) do
    local items = vim.inspect(c.items, { newline = " ", indent = " " })
    local names = vim.inspect(c.names, { newline = " ", indent = " " })
    local expected = vim.inspect(c.expected, { newline = " ", indent = " " })

    it(("Sorters.new(%s):apply(%s) == %s"):format(names, items, expected), function()
      local sorters = require("thetto.core.items.sorters").new(c.names)
      local actual = sorters:apply(c.items)
      assert.is_same(c.expected, actual)
    end)
  end
end)
