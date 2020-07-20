local helper = require "test.helper"
local assert = helper.assert
local command = helper.command

describe("vim/keymap source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show keymaps", function()
    command("nnoremap <buffer> <Space>hoge :<C-u>tabedit<CR>")

    command("Thetto vim/keymap")
    helper.sync_input({"hoge"})

    command("ThettoDo move_to_list")

    assert.exists_pattern("n noremap <buffer> <Space>hoge :<C-U>tabedit<CR>")

    command("ThettoDo")

    assert.tab_count(2)
  end)

end)
