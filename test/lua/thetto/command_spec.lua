local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("thetto", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can filter", function()
    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line")
    helper.sync_input({"2"})

    command("ThettoDo move_to_list")

    assert.current_line("test2")
    assert.not_exists_pattern("test1")
  end)

  it("can move to filter", function()
    command("Thetto line --no-insert")

    assert.window_count(3)
    assert.filetype("thetto")

    command("ThettoDo move_to_input")

    assert.filetype("thetto-input")
  end)

  it("can move to list", function()
    command("Thetto line")

    assert.window_count(3)
    assert.filetype("thetto-input")

    command("ThettoDo move_to_list")

    assert.filetype("thetto")
  end)

  it("can move to list even if empty", function()
    command("Thetto line")
    helper.sync_input({"test"})

    assert.window_count(3)
    assert.filetype("thetto-input")

    command("ThettoDo move_to_list")

    assert.filetype("thetto")
  end)

  it("can resume latest", function()
    helper.set_lines([[
test11
test21
test22]])

    command("Thetto line")
    helper.sync_input({"test2"})

    command("ThettoDo move_to_list")
    command("normal! G")

    command("ThettoDo quit")
    command("Thetto --resume")

    command("ThettoDo move_to_input")

    assert.window_count(3)
    assert.filetype("thetto-input")
    assert.current_line("test2")

    command("ThettoDo move_to_list")

    assert.current_line("test22")
    command("normal! gg")
    assert.current_line("test21")
  end)

  it("can resume by source", function()
    helper.set_lines([[
test11
test21
test22]])

    command("Thetto line")
    helper.sync_input({"test2"})

    command("ThettoDo quit")
    command("Thetto vim/runtimepath")
    command("ThettoDo quit")
    command("Thetto line --resume")

    assert.window_count(3)
    assert.filetype("thetto-input")
    assert.current_line("test2")

    command("ThettoDo move_to_list")

    assert.current_line("test21")
  end)

  it("can filter with ignorecase", function()
    helper.set_lines([[
test1
TEST2
test2
test3]])

    command("Thetto line --ignorecase")
    helper.sync_input({"test2"})

    command("ThettoDo move_to_list")

    assert.current_line("TEST2")
  end)

  it("can filter with smartcase", function()
    helper.set_lines([[
TEST1
test1
hoge]])

    command("Thetto line --smartcase")
    helper.sync_input({"t"})

    command("ThettoDo move_to_list")

    assert.exists_pattern("TEST1")
    assert.exists_pattern("test1")
    assert.not_exists_pattern("hoge")

    command("ThettoDo move_to_input")

    command("normal! dd")
    helper.sync_input({"TE"})

    command("ThettoDo move_to_list")

    assert.exists_pattern("TEST1")
    assert.not_exists_pattern("test1")
    assert.not_exists_pattern("hoge")
  end)

  it("should exist only one in a tab", function()
    command("Thetto line")
    command("Thetto vim/runtimepath")

    assert.window_count(3)
  end)

end)
