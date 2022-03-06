local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")
local util = helper.require("thetto.util")

describe("file/grep source", function()
  before_each(function()
    helper.before_each()
    helper.new_file(
      "target",
      [[
hoge
foo
bar]]
    )
  end)
  after_each(helper.after_each)

  it("can show grep results", function()
    helper.sync_open("file/grep", { opts = { insert = false, pattern = "hoge" } })

    assert.exists_pattern("hoge")

    helper.search("target")
    thetto.execute()

    assert.current_line("hoge")
  end)

  it("can grep the word under the cursor", function()
    helper.set_lines([[
hoge
foo]])
    vim.cmd("setlocal buftype=nofile")
    helper.search("hoge")

    helper.sync_open("file/grep", {
      opts = {
        insert = false,
        pattern = function()
          return vim.fn.expand("<cword>")
        end,
      },
    })

    assert.exists_pattern("hoge")

    helper.search("target")
    thetto.execute()

    assert.current_line("hoge")
  end)

  it("can show grep results in project dir", function()
    helper.new_directory("0_root_pattern")
    helper.new_file("0_root_pattern/in_root_pattern", [[hoge in root_pattern]])

    helper.sync_open(
      "file/grep",
      { opts = { insert = false, cwd = util.cwd.project({ "0_root_pattern" }), pattern = "hoge" } }
    )

    assert.exists_pattern("0_root_pattern/in_root_pattern:1 hoge in root_pattern")
  end)

  it("can execute tab_open", function()
    helper.sync_open("file/grep", { opts = { insert = false, pattern = "foo" } })

    assert.exists_pattern("foo")

    thetto.execute("tab_open")

    assert.tab_count(2)
    assert.current_line("foo")
  end)

  it("can execute vsplit_open", function()
    helper.sync_open("file/grep", { opts = { insert = false, pattern = "foo" } })

    assert.exists_pattern("foo")

    thetto.execute("vsplit_open")

    assert.window_count(2)
    assert.current_line("foo")
  end)

  it("can grep interactively", function()
    local collector = helper.sync_open("file/grep", {
      opts = { insert = false, filters = { "interactive" } },
    })

    assert.current_line("")

    thetto.execute("move_to_input")
    helper.sync_input({ "hoge" })
    assert.is_true(collector:wait())
    helper.wait_ui(function()
      thetto.execute("move_to_list")
    end)

    assert.current_line("target:1 hoge")
  end)

  it("can grep no result pattern interactively", function()
    local collector = helper.sync_open("file/grep", { opts = { filters = { "interactive" } } })

    helper.sync_input({ "hoge" })
    helper.sync_input({ "bar" })
    helper.wait_ui(function()
      thetto.execute("move_to_list")
    end)

    assert.current_line("")
    assert.is_true(collector:wait())
  end)

  it("can grep with camelcase pattern", function()
    helper.sync_open("file/grep", { opts = { insert = false, ignorecase = true, pattern = "Foo" } })

    assert.exists_pattern("foo")
  end)

  it("can show grep results with including :digits: text", function()
    helper.new_file("file", [[  test :111:  ]])

    helper.sync_open("file/grep", { opts = { insert = false, pattern = "test" } })

    assert.exists_pattern("file:1   test :111:  ")
  end)
end)
