local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

describe("thetto.start() default ui", function()
  local notify = vim.notify
  before_each(function()
    helper.before_each()
    vim.notify = notify
  end)
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

  it("can filter items by input", function()
    local p1 = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
        }
      end,
    }, {
      pipeline_stages_factory = require("thetto.util.pipeline").list({
        require("thetto.util.filter").by_name("substring", { debounce_ms = 1 }),
      }),
    })
    helper.wait(p1)

    helper.input("line2")
    thetto.call_consumer("move_to_list")

    assert.lines([[
line2]])
  end)

  it("can change source input pattern interactively", function()
    local p1 = thetto.start({
      collect = function(source_ctx)
        local pattern = source_ctx.pattern or ""
        return {
          { value = pattern .. "1" },
          { value = pattern .. "2" },
        }
      end,
    }, {
      pipeline_stages_factory = require("thetto.util.pipeline").list({
        require("thetto.util.filter").by_name("source_input", { debounce_ms = 1 }),
      }),
    })
    helper.wait(p1)

    thetto.call_consumer("move_to_list")
    assert.lines([[
1
2]])

    thetto.call_consumer("move_to_input")
    helper.input("a")
    thetto.call_consumer("move_to_list")
    assert.lines([[
a1
a2]])

    thetto.call_consumer("move_to_input")
    helper.input("b")
    thetto.call_consumer("move_to_list")
    assert.lines([[
ab1
ab2]])
  end)

  it("can sort items", function()
    local p1 = thetto.start({
      collect = function()
        return {
          {
            value = "line1",
            row = 3,
          },
          {
            value = "line2",
            row = 1,
          },
          {
            value = "line3",
            row = 2,
          },
        }
      end,
    }, {
      pipeline_stages_factory = require("thetto.util.pipeline").list({
        require("thetto.util.sorter").field_by_name("row"),
      }),
    })
    helper.wait(p1)

    thetto.call_consumer("move_to_list")

    assert.lines([[
line2
line3
line1]])
  end)

  it("can filter source items", function()
    local p1 = thetto.start({
      collect = function()
        return {
          {
            value = "line1",
            row = 3,
          },
          {
            value = "line2",
            row = 1,
          },
          {
            value = "line3",
            row = 2,
          },
        }
      end,
      filter = require("thetto.util.source").filter(function(item)
        return item.value == "line2"
      end),
    })
    helper.wait(p1)

    thetto.call_consumer("move_to_list")

    assert.lines([[
line2]])
  end)

  it("can set default list cursor position", function()
    local p = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
          { value = "line3" },
          { value = "line4" },
        }
      end,
    }, {
      pipeline_stages_factory = require("thetto.util.pipeline").list({
        require("thetto.util.sorter").field_by_name("value", true),
      }),
      item_cursor_factory = require("thetto.util.item_cursor").search(function(item)
        return item.value == "line2"
      end),
    })
    helper.wait(p)

    thetto.call_consumer("move_to_list")

    assert.current_line("line2")
  end)

  it("can preview item", function()
    local p = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
          { value = "line3" },
        }
      end,
      actions = {
        get_preview = function(item)
          return nil, {
            lines = { "previewed " .. item.value },
            title = "test",
          }
        end,
      },
    })
    helper.wait(p)

    helper.go_to_sidecar(" test ")
    assert.current_line("previewed line1")
  end)

  it("can close even if not can_resume", function()
    local p = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
          { value = "line3" },
        }
      end,
      can_resume = false,
    })
    helper.wait(p)

    thetto.quit()

    assert.window_count(1)
  end)

  it("echoes warning message without ui if source causes error in early stage", function()
    local messages = {}
    vim.notify = function(msg)
      table.insert(messages, msg)
    end

    local p = thetto.start({
      collect = function()
        return nil, "early stage error for test"
      end,
    })
    helper.wait(p)

    assert.equals("[thetto] early stage error for test", messages[1])
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
      consumer_factory = require("thetto.util.consumer").immediate({ action_name = "append" }),
    })
    helper.wait(p)

    assert.lines([[line1]])
  end)

  it("can merge sources", function()
    local p = thetto.start(require("thetto.util.source").merge({
      {
        collect = function(source_ctx)
          return {
            { value = "line1" .. source_ctx.opts.test1 },
            { value = "line2" },
          }
        end,
        opts = { test1 = "a" },
      },
      {
        collect = function(source_ctx)
          return {
            { value = "line3" .. source_ctx.opts.test1 },
            { value = "line4" },
          }
        end,
        opts = { test1 = "b" },
      },
    }))
    helper.wait(p)

    thetto.call_consumer("move_to_list")

    assert.lines([[
line1a
line2
line3b
line4]])
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

    local p2 = require("thetto.util.action").execute("append")
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

    thetto.quit()

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
    thetto.quit()

    local p2 = thetto.resume()
    helper.wait(p2)

    assert.lines([[
line1
line2]])
  end)

  it("can resume previous and next", function()
    local p1 = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
        }
      end,
    })
    helper.wait(p1)

    thetto.quit()

    local p2 = thetto.start({
      collect = function()
        return {
          { value = "line3" },
          { value = "line4" },
        }
      end,
    })
    helper.wait(p2)

    local p3 = thetto.resume({ offset = -1 })
    helper.wait(p3)

    thetto.call_consumer("move_to_list")
    assert.lines([[
line1
line2]])

    local p4 = thetto.resume({ offset = 1 })
    helper.wait(p4)

    thetto.call_consumer("move_to_list")
    assert.lines([[
line3
line4]])
  end)

  it("can resume error", function()
    local messages = {}
    vim.notify = function(msg)
      table.insert(messages, msg)
    end

    local p1 = thetto.start({
      collect = function()
        return nil, "early stage error for test"
      end,
    })
    helper.wait(p1)

    local p2 = thetto.resume()
    helper.wait(p2)

    assert.is_same({
      "[thetto] early stage error for test",
      "[thetto] early stage error for test",
    }, messages)
  end)

  it("can resume by specified offset with wrap", function()
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
    thetto.quit()

    local p2 = thetto.start({
      collect = function()
        return {
          { value = "line3" },
          { value = "line4" },
        }
      end,
    })
    helper.wait(p2)
    thetto.call_consumer("move_to_list")
    thetto.quit()

    local p3 = thetto.resume()
    helper.wait(p3)

    local p4 = thetto.resume({ offset = -1 })
    helper.wait(p4)

    assert.lines([[
line1
line2]])

    local p5 = thetto.resume({ offset = -1 })
    helper.wait(p5)

    assert.lines([[
line3
line4]])
  end)

  it("can resume source grouped by source key", function()
    local p1 = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
        }
      end,
      key = function()
        return "key"
      end,
    })
    helper.wait(p1)
    helper.input("a")
    thetto.quit()

    local p2 = thetto.start({
      collect = function()
        return {
          { value = "line1" },
          { value = "line2" },
          { value = "line3" },
        }
      end,
      key = function()
        return "key"
      end,
    })
    helper.wait(p2)

    thetto.call_consumer("move_to_list")

    local p3 = thetto.resume({ offset = 1 })
    helper.wait(p3)

    assert.lines([[
line1
line2
line3]])
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

    local got = require("thetto.util.source").by_name("test").collect()
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

    local got = require("thetto.util.kind").by_name("test").action_test()
    assert.is_same("value", got)
  end)
end)
