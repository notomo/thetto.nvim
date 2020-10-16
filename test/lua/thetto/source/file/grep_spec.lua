local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("file/grep source", function()

  before_each(function()
    helper.before_each()
    helper.new_file("target", [[
hoge
foo
bar]])
  end)
  after_each(helper.after_each)

  it("can show grep results", function()
    helper.sync_open("file/grep", "--no-insert", "--pattern=hoge")

    assert.exists_pattern("hoge")

    helper.search("target")
    command("ThettoDo")

    assert.current_line("hoge")
  end)

  it("can grep the word under the cursor", function()
    helper.set_lines([[
hoge
foo]])
    command("setlocal buftype=nofile")
    helper.search("hoge")

    helper.sync_open("file/grep", "--no-insert", "--pattern-type=word")

    assert.exists_pattern("hoge")

    helper.search("target")
    command("ThettoDo")

    assert.current_line("hoge")
  end)

  it("can show grep results in project dir", function()
    helper.new_directory("0_root_pattern")
    helper.new_file("0_root_pattern/in_root_pattern", [[hoge in root_pattern]])

    require("thetto/target/project").root_patterns = {"0_root_pattern"}

    helper.sync_open("file/grep", "--no-insert", "--target=project", "--pattern=hoge")

    assert.exists_pattern("0_root_pattern/in_root_pattern:1 hoge in root_pattern")
  end)

  it("can execute tab_open", function()
    helper.sync_open("file/grep", "--no-insert", "--pattern=foo")

    assert.exists_pattern("foo")

    command("ThettoDo tab_open")

    assert.tab_count(2)
    assert.current_line("foo")
  end)

  it("can execute vsplit_open", function()
    helper.sync_open("file/grep", "--no-insert", "--pattern=foo")

    assert.exists_pattern("foo")

    command("ThettoDo vsplit_open")

    assert.window_count(2)
    assert.current_line("foo")
  end)

  it("can grep interactively", function()
    local collector = helper.sync_open("file/grep", "--no-insert", "--filters=interactive")

    assert.current_line("")

    command("ThettoDo move_to_input")
    helper.sync_input({"hoge"})
    assert.is_true(collector:wait())
    helper.wait_ui(function()
      command("ThettoDo move_to_list")
    end)

    assert.current_line("target:1 hoge")
  end)

  it("can grep with camelcase pattern", function()
    helper.sync_open("file/grep", "--no-insert", "--ignorecase", "--pattern=Foo")

    assert.exists_pattern("foo")
  end)

end)
