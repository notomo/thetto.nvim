local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("vim/autocmd source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show autocmds", function()
    command("autocmd VimResume <buffer> echomsg 'hoge_autocmd'")

    command("Thetto vim/autocmd")
    helper.sync_input({"hoge_autocmd"})

    command("ThettoDo move_to_list")
    helper.search("hoge_autocmd")

    command("ThettoDo tab_open")
    assert.tab_count(2)
  end)

end)
