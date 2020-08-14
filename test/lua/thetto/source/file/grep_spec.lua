local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("file/grep source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show grep results", function()
    vim.api.nvim_set_current_dir("./test/_test_data")

    helper.sync_open("file/grep", "--no-insert", "--pattern=hoge")

    assert.exists_pattern("hoge")
    helper.search("grep")

    command("ThettoDo")

    assert.current_line("hoge")
  end)

  it("can grep the word under the cursor", function()
    vim.api.nvim_set_current_dir("./test/_test_data")

    helper.set_lines([[
hoge
foo]])
    command("setlocal buftype=nofile")
    helper.search("hoge")

    helper.sync_open("file/grep", "--no-insert", "--pattern-type=word")

    assert.exists_pattern("hoge")
    helper.search("grep")

    command("ThettoDo")

    assert.current_line("hoge")
  end)

  it("can show grep results in project dir", function()
    require("thetto/target/project").root_patterns = {"0_root_pattern"}
    vim.api.nvim_set_current_dir("./test/_test_data/dir")

    helper.sync_open("file/grep", "--no-insert", "--target=project", "--pattern=hoge")

    assert.exists_pattern("0_root_pattern/in_root_pattern:1 hoge in root_pattern")
  end)

  it("can execute tab_open", function()
    vim.api.nvim_set_current_dir("./test/_test_data")

    helper.sync_open("file/grep", "--no-insert", "--pattern=foo")

    assert.exists_pattern("foo")

    command("ThettoDo tab_open")

    assert.tab_count(2)
    assert.current_line("foo")
  end)

  it("can execute vsplit_open", function()
    vim.api.nvim_set_current_dir("./test/_test_data")

    helper.sync_open("file/grep", "--no-insert", "--pattern=foo")

    assert.exists_pattern("foo")

    command("ThettoDo vsplit_open")

    assert.window_count(2)
    assert.current_line("foo")
  end)

end)
