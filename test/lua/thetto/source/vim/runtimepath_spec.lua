local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("vim/runtimepath source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can runtime paths", function()
    command("Thetto vim/runtimepath --no-insert")

    helper.search("thetto.nvim")

    vim.api.nvim_set_current_dir("./test")
    command("ThettoDo cd")

    assert.current_dir(helper.root)
  end)

  it("can execute tab_open", function()
    command("Thetto vim/runtimepath --no-insert")

    helper.search("thetto.nvim")

    vim.api.nvim_set_current_dir("./test")
    command("ThettoDo tab_open")

    assert.tab_count(2)
    assert.current_dir(helper.root)
  end)

  it("can execute vsplit_open", function()
    command("Thetto vim/runtimepath --no-insert")

    helper.search("thetto.nvim")

    vim.api.nvim_set_current_dir("./test")
    command("ThettoDo vsplit_open")

    assert.window_count(2)
    assert.current_dir(helper.root)
  end)

end)
