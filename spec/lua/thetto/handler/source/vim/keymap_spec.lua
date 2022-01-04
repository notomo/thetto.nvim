local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/keymap source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show and execute keymaps", function()
    vim.cmd("nnoremap <silent> <buffer> <Space>hoge :<C-u>tabedit<CR>")

    thetto.start("vim/keymap")
    helper.sync_input({ "hoge" })

    thetto.execute("move_to_list")

    assert.exists_pattern("n noremap <silent> <buffer> <Space>hoge :<C-U>tabedit<CR>")

    thetto.execute()

    assert.tab_count(2)
  end)
end)
