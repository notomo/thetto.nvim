local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("vim/autocmd source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show autocmds", function()
    vim.cmd("autocmd VimResume <buffer> echomsg 'hoge_autocmd'")

    thetto.start("vim/autocmd")
    helper.sync_input({ "hoge_autocmd" })

    thetto.execute("move_to_list")
    helper.search("hoge_autocmd")

    assert.exists_pattern("hoge_autocmd")
  end)

  it("can delete autocmd group", function()
    vim.cmd("augroup target_group")
    vim.cmd("autocmd VimResume <buffer> echomsg 'target_autocmd'")
    vim.cmd("augroup END")

    thetto.start("vim/autocmd")
    helper.sync_input({ "target_autocmd" })

    thetto.execute("move_to_list")
    helper.search("target_autocmd")

    thetto.execute("delete_group")

    thetto.start("vim/autocmd")
    helper.sync_input({ "target_autocmd" })
    thetto.execute("move_to_list")

    assert.no.exists_pattern("target_autocmd")
  end)

  it("can delete an autocmd by pattern", function()
    vim.cmd("augroup target_group")
    vim.cmd("autocmd VimResume test1 echomsg 'the_target_autocmd'")
    vim.cmd("autocmd VimResume test2 echomsg 'not_target_autocmd'")
    vim.cmd("augroup END")

    thetto.start("vim/autocmd")
    helper.sync_input({ "target_autocmd" })

    thetto.execute("move_to_list")
    helper.search("target_autocmd")

    thetto.execute("delete_autocmd_by_pattern")

    thetto.start("vim/autocmd")
    helper.sync_input({ "target_autocmd" })
    thetto.execute("move_to_list")

    assert.no.exists_pattern("the_target_autocmd")
    assert.exists_pattern("not_target_autocmd")
  end)
end)
