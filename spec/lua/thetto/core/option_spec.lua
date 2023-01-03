local helper = require("thetto.test.helper")

describe("thetto.core.option filters", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  for _, c in ipairs({
    {
      name = "has default filters",
      raw_opts = {},
      source_config = {},
      source_filters = nil,
      want = { "substring" },
    },
    {
      name = "can use argument filters table",
      raw_opts = {
        filters = { "regex" },
      },
      source_config = {},
      source_filters = nil,
      want = { "regex" },
    },
    {
      name = "can use argument filters function",
      raw_opts = {
        filters = function(filters)
          local new = { "regex" }
          vim.list_extend(new, filters)
          return new
        end,
      },
      source_config = {},
      source_filters = { "-regex" },
      want = { "regex", "-regex" },
    },
    {
      name = "can use source config filters table",
      raw_opts = {},
      source_config = {
        filters = { "regex" },
      },
      source_filters = nil,
      want = { "regex" },
    },
    {
      name = "can use source config filters function",
      raw_opts = {},
      source_config = {
        filters = function(filters)
          local new = { "regex" }
          vim.list_extend(new, filters)
          return new
        end,
      },
      source_filters = { "-regex" },
      want = { "regex", "-regex" },
    },
    {
      name = "can use source filters table",
      raw_opts = {},
      source_config = {},
      source_filters = { "regex" },
      want = { "regex" },
    },
    {
      name = "can use multiple filters function",
      raw_opts = {},
      source_config = {
        filters = function(filters)
          local new = { "regex" }
          vim.list_extend(new, filters)
          return new
        end,
      },
      source_filters = function()
        return { "-regex" }
      end,
      want = { "regex", "-regex" },
    },
  }) do
    it(c.name, function()
      local option = require("thetto.core.option").Option.new(c.raw_opts, {}, c.source_config)
      local got = option.filters(c.source_filters)
      assert.is_same(c.want, got)
    end)
  end
end)
