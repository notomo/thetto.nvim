local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

local _cursor = 8888

describe("thetto action completion", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show action names", function()
    helper.set_lines([[
test1]])
    command("Thetto line --no-insert")

    local result = vim.fn["thetto#complete#action"]("", "ThettoDo ", _cursor)

    assert.completion_contains(result, "open")
  end)

  it("includes custom source action names", function()
    local actions = require("thetto/custom").source_actions
    actions["line"] = {
      action_hoge = function(_)
      end,
    }

    helper.set_lines([[
test1]])
    command("Thetto line --no-insert")

    local result = vim.fn["thetto#complete#action"]("", "ThettoDo ", _cursor)

    assert.completion_contains(result, "hoge")
  end)

  it("includes custom kind action names", function()
    local actions = require("thetto/custom").kind_actions
    actions["position"] = {
      action_foo = function(_)
      end,
    }

    helper.set_lines([[
test1]])
    command("Thetto line --no-insert")

    local result = vim.fn["thetto#complete#action"]("", "ThettoDo ", _cursor)

    assert.completion_contains(result, "foo")
  end)

end)

describe("thetto source completion", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show source names", function()
    local result = vim.fn["thetto#complete#source"]("", "Thetto ", _cursor)

    assert.completion_contains(result, "source")
  end)

end)
