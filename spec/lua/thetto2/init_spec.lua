local helper = require("thetto2.test.helper")
local thetto = helper.require("thetto2")

describe("thetto.start() default ui", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("shows item list", function()
    local p = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
        }
      end,
    })
    helper.wait(p)

    thetto.call_consumer("move_to_list")

    assert.lines([[
line1
line2]])
  end)
end)

describe("thetto.start() immediate", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("executes action immedately", function()
    local p = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
        }
      end,
    }, {
      consumer_factory = require("thetto2.util.consumer").immediate({ action_name = "append" }),
    })
    helper.wait(p)

    assert.lines([[line1]])
  end)
end)

describe("thetto.execute()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can execute action", function()
    local p1 = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
        }
      end,
    })
    helper.wait(p1)

    local items = thetto.get()
    local item_action_groups = require("thetto2.util.action").grouping(items, { action_name = "append" })
    local p2 = thetto.execute(item_action_groups)
    helper.wait(p2)

    assert.lines([[line1]])
  end)
end)

describe("thetto.call_consumer()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can close default ui", function()
    local p = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
        }
      end,
    })
    helper.wait(p)

    thetto.call_consumer("quit")

    assert.window_count(1)
  end)
end)

describe("thetto.resume()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can resume default ui", function()
    local p1 = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
        }
      end,
    })
    helper.wait(p1)

    thetto.call_consumer("move_to_list")
    thetto.call_consumer("quit")

    local p2 = thetto.resume()
    helper.wait(p2)

    assert.lines([[
line1
line2]])
  end)
end)

describe("thetto.reload()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("restarts source", function()
    local items = {
      { value = "line1" },
      { value = "line2" },
    }

    local p1 = thetto.start({
      collect = function()
        return items
      end,
    })
    helper.wait(p1)

    thetto.call_consumer("move_to_list")
    table.insert(items, {
      value = "line3",
    })

    local p2 = thetto.reload()
    helper.wait(p2)

    assert.lines([[
line1
line2
line3]])
  end)
end)

describe("thetto.get()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("returns get current item", function()
    local p = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
        }
      end,
    })
    helper.wait(p)

    local got = thetto.get()
    local want = {
      {
        value = "line1",
        kind_name = "base",
        index = 1,
      },
    }
    assert.same(want, got)
  end)

  it("returns selected items if selected", function()
    local p = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
          { value = "line3" },
        }
      end,
    })
    helper.wait(p)

    thetto.call_consumer("move_to_list")
    vim.cmd.normal({ bang = true, args = { "j" } })
    thetto.call_consumer("toggle_selection")
    vim.cmd.normal({ bang = true, args = { "j" } })
    thetto.call_consumer("toggle_selection")

    local got = thetto.get()
    local want = {
      {
        value = "line2",
        kind_name = "base",
        index = 2,
      },
      {
        value = "line3",
        kind_name = "base",
        index = 3,
      },
    }
    assert.same(want, got)
  end)

  it("returns metadata", function()
    local p = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
        }
      end,
      actions = {
        opts = {
          test = "value",
        },
      },
    })
    helper.wait(p)

    local _, got = thetto.get()
    local want = {
      actions = {
        opts = {
          test = "value",
        },
      },
    }
    assert.same(want, got)
  end)
end)

describe("thetto.register_source()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can register source", function()
    thetto.register_source("test", {
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
        }
      end,
    })

    local got = require("thetto2.util.source").by_name("test").collect()
    assert.is_same({
      { value = "line1" },
      { value = "line2" },
    }, got)
  end)
end)

describe("thetto.register_kind()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can register kind", function()
    thetto.register_kind("test", {
      action_test = function()
        return "value"
      end,
    })

    local got = require("thetto2.util.kind").by_name("test").action_test()
    assert.is_same("value", got)
  end)
end)
