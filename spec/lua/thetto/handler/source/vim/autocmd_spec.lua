local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

describe("vim/autocmd source", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show autocmds", function()
    vim.api.nvim_create_autocmd({ "VimResume" }, {
      buffer = 0,
      command = [[echomsg 'hoge_autocmd']],
    })

    thetto.start("vim/autocmd")
    helper.sync_input({ "hoge_autocmd" })

    thetto.execute("move_to_list")
    helper.search("hoge_autocmd")

    assert.exists_pattern("hoge_autocmd")
  end)

  it("can delete autocmd group", function()
    local group = vim.api.nvim_create_augroup("target_group", {})
    vim.api.nvim_create_autocmd({ "VimResume" }, {
      group = group,
      buffer = 0,
      command = [[echomsg 'target_autocmd']],
    })
    vim.api.nvim_create_autocmd({ "FocusLost" }, {
      buffer = 0,
      command = [[echomsg 'other_autocmd']],
    })

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
    local group = vim.api.nvim_create_augroup("target_group", {})
    vim.api.nvim_create_autocmd({ "VimResume" }, {
      group = group,
      pattern = "test1",
      command = [[echomsg 'the_target_autocmd']],
    })
    vim.api.nvim_create_autocmd({ "VimResume" }, {
      group = group,
      pattern = "test2",
      command = [[echomsg 'not_target_autocmd']],
    })

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
