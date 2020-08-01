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

    command("ThettoDo move_to_info")
    assert.virtual_text("line [ 1 / 3 ]")

    command("ThettoDo move_to_list")

    assert.current_line("test2")
    assert.not_exists_pattern("test1")
  end)

  it("can move to filter", function()
    command("Thetto line --no-insert")

    assert.window_count(5)
    assert.filetype("thetto")

    command("ThettoDo move_to_input")

    assert.filetype("thetto-input")
  end)

  it("can move to list", function()
    command("Thetto line")

    assert.window_count(5)
    assert.filetype("thetto-input")

    command("ThettoDo move_to_list")

    assert.filetype("thetto")
  end)

  it("can move to list even if empty", function()
    command("Thetto line")
    helper.sync_input({"test"})

    assert.window_count(5)
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

    assert.window_count(5)
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

    assert.window_count(5)
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

    assert.window_count(5)
  end)

  it("should show an error message if not found source", function()
    assert.error_message("not found source: invalid", function()
      command("Thetto invalid")
    end)
    assert.window_count(1)
  end)

  it("should show an error message if not found action", function()
    command("Thetto line")
    assert.error_message("not found action: invalid", function()
      command("ThettoDo invalid")
    end)
    assert.window_count(5)
  end)

  it("can resume with offset", function()
    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line")
    command("ThettoDo quit")

    command("ThettoDo --resume --offset=-1")
    assert.current_line("test1")

    command("ThettoDo --resume --offset=1")
    assert.window_count(1)
    assert.current_line("test2")

    command("ThettoDo --resume --offset=1")
    assert.window_count(1)
    assert.current_line("test3")

    command("ThettoDo --resume --offset=1")
    assert.current_line("test3")
  end)

  it("can custom source action", function()
    local called = false
    local actions = require("thetto/base_kind").source_user_actions
    actions["line"] = {
      action_hoge = function(_)
        called = true
      end,
    }

    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line --action=hoge")
    command("ThettoDo")

    assert.is_true(called)
  end)

  it("can custom kind action", function()
    local called = false
    local actions = require("thetto/base_kind").user_actions
    actions["directory"] = {
      action_hoge = function(_)
        called = true
      end,
    }

    helper.set_lines([[
test1
test2
test3]])

    command("Thetto vim/runtimepath --action=hoge")
    command("ThettoDo")

    assert.is_true(called)
  end)

  it("can input lua escape character", function()
    helper.set_lines([[
test1
test%
test3]])

    command("Thetto line")
    helper.sync_input({"%"})

    command("ThettoDo move_to_list")

    assert.current_line("test%")
  end)

  it("can execute debug_print", function()
    helper.set_lines([[
test1
test2]])

    command("Thetto line")

    command("ThettoDo debug_print")

    assert.exists_message("row = 1")
    assert.exists_message("value = \"test1\"")
  end)

  it("can select items and execute action", function()
    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line --no-insert")

    command("ThettoDo toggle_selection")
    command("normal! j")
    command("ThettoDo toggle_selection")
    command("normal! j")

    command("ThettoDo toggle_selection")
    command("ThettoDo toggle_selection")

    command("ThettoDo tab_open")

    assert.tab_count(3)
    assert.current_line("test2")
  end)

  it("can execute toggle_all_selection", function()
    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line --no-insert")

    helper.search("test2")
    command("ThettoDo toggle_selection")

    command("ThettoDo toggle_all_selection")

    command("ThettoDo tab_open")

    assert.tab_count(3)
    assert.current_line("test3")
    command("tabclose")
    assert.current_line("test1")
  end)

  it("stops the unfinished job on closed", function()
    local job = require("thetto/job").new({"sleep", "9"}, {})
    require("thetto/source/line").collect = function(_)
      return {}, job
    end

    command("Thetto line --no-insert")
    command("ThettoDo quit")

    assert.is_false(job:is_running())
  end)

  it("can execute yank", function()
    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line --no-insert")
    helper.search("test2")

    command("ThettoDo yank")

    assert.register("+", "test2")
  end)

  it("can open with action opts", function()
    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line --no-insert --xx-register=1")
    helper.search("test3")

    command("ThettoDo yank")

    assert.register("1", "test3")
  end)

  it("can execute append", function()
    helper.set_lines([[
test1
test2
test3]])
    command("normal! $")

    command("Thetto line --no-insert")
    helper.search("test2")

    command("ThettoDo append")

    assert.current_line("test1test2")
  end)

  it("can use sorters", function()
    helper.set_lines([[
te
t
test
tes]])

    command("Thetto line --no-insert --sorters=length")

    assert.current_line("t")
    command("normal! j")
    assert.current_line("te")
    command("normal! j")
    assert.current_line("tes")
  end)

end)