local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("line source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show current buffer lines with normal mode", function()
    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line --no-insert")

    assert.window_count(6)
    assert.filetype("thetto")

    helper.search("test2")

    command("ThettoDo")

    assert.current_line("test2")
    assert.filetype("")
  end)

  it("can show current buffer lines with insert mode", function()
    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line")

    assert.window_count(6)
    assert.filetype("thetto-input")

    command("ThettoDo")

    assert.current_line("test1")
    assert.filetype("")
  end)

  it("can execute tab_oepn", function()
    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line --no-insert")

    helper.search("test2")

    command("ThettoDo tab_open")

    assert.tab_count(2)
    assert.current_line("test2")
  end)

  it("can execute vsplit_open", function()
    helper.set_lines([[
test1
test2
test3]])

    command("Thetto line --no-insert")

    helper.search("test2")

    command("ThettoDo vsplit_open")

    assert.window_count(2)
    assert.current_line("test2")
  end)

  it("can execute open", function()
    helper.set_lines([[
test1
test2
test3]])
    command("vsplit")
    command("wincmd w")
    local window = vim.api.nvim_get_current_win()

    command("Thetto line --no-insert")

    command("ThettoDo open")

    assert.current_window(window)
  end)

end)
