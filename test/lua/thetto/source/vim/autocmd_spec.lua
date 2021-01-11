local helper = require("thetto/lib/testlib/helper")
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

  it("can delete autocmd", function()
    command("augroup target_group")
    command("autocmd VimResume <buffer> echomsg 'target_autocmd'")
    command("augroup END")

    command("Thetto vim/autocmd")
    helper.sync_input({"target_autocmd"})

    command("ThettoDo move_to_list")
    helper.search("target_autocmd")

    command("ThettoDo delete_group")

    command("Thetto vim/autocmd")
    helper.sync_input({"target_autocmd"})
    command("ThettoDo move_to_list")

    assert.no.exists_pattern("target_autocmd")
  end)

end)
