local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("runtimepath source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can runtime paths", function()
    command("Thetto runtimepath --no-insert")

    helper.search("thetto.nvim")

    vim.api.nvim_set_current_dir("./test")
    command("ThettoDo cd")

    assert.current_dir(helper.root)
  end)

end)
