local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("grep source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show grep results", function()
    vim.api.nvim_set_current_dir("./test/_test_data")

    helper.sync_open("grep", "--no-insert", "--input=hoge")

    assert.exists_pattern("hoge")

    command("ThettoDo")

    assert.current_line("hoge")
  end)

end)
