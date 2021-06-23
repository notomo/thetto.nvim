local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")

describe("thetto", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can open ui in list buffer", function()
    thetto.start("line", {opts = {insert = false}})

    assert.filetype("thetto")
  end)

  it("can open ui in input buffer", function()
    thetto.start("line")

    assert.filetype("thetto-input")
  end)

  it("can scroll ui by offset", function()
    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line", {opts = {insert = false, offset = 10}})

    assert.current_line("test3")
  end)

  it("can close ui by :quit", function()
    helper.set_lines([[
test]])

    thetto.start("line", {opts = {insert = false}})
    vim.cmd("quit")

    assert.window_count(1)
  end)

  it("should exist only one in a tab", function()
    thetto.start("line")
    thetto.start("vim/runtimepath")

    assert.window_count(4)
  end)

  it("should exist same source only one", function()
    thetto.start("line")
    vim.cmd("tabedit")
    thetto.start("line")

    assert.window_count(4)
  end)

  it("can resume even if opened", function()
    thetto.start("line")
    vim.cmd("tabedit")

    thetto.resume()
    assert.window_count(4)
  end)

  it("goes back to original window when quit resumed thetto", function()
    thetto.start("line")
    vim.cmd("tabedit")
    local current = vim.api.nvim_get_current_win()

    thetto.resume()
    thetto.start("line")
    thetto.execute("quit")

    assert.window(current)
  end)

  it("can filter by substring", function()
    thetto.setup({sorters = {"length"}})
    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line")
    helper.sync_input({"2"})

    thetto.execute("move_to_list")

    assert.current_line("test2")
    assert.no.exists_pattern("test1")
  end)

  it("can move to filter", function()
    thetto.start("line", {opts = {insert = false}})

    assert.filetype("thetto")

    thetto.execute("move_to_input")

    assert.filetype("thetto-input")
  end)

  it("can move to list", function()
    thetto.start("line")

    assert.filetype("thetto-input")

    thetto.execute("move_to_list")

    assert.filetype("thetto")
  end)

  it("can move to list even if empty", function()
    thetto.start("line")
    helper.sync_input({"test"})

    assert.filetype("thetto-input")

    thetto.execute("move_to_list")

    assert.filetype("thetto")
  end)

  it("can resume latest", function()
    helper.set_lines([[
test11
test21
test22]])

    thetto.start("line")
    helper.sync_input({"test2"})

    thetto.execute("move_to_list")
    vim.cmd("normal! G")

    thetto.execute("quit")
    thetto.resume()

    thetto.execute("move_to_input")

    assert.filetype("thetto-input")
    assert.current_line("test2")

    thetto.execute("move_to_list")

    assert.current_line("test22")
    vim.cmd("normal! gg")
    assert.current_line("test21")
  end)

  it("can resume by source", function()
    helper.set_lines([[
test11
test21
test22]])

    thetto.start("line")
    helper.sync_input({"test2"})

    thetto.execute("quit")
    thetto.start("vim/runtimepath")
    thetto.execute("quit")
    thetto.resume("line")

    assert.filetype("thetto-input")
    assert.current_line("test2")

    thetto.execute("move_to_list")

    assert.current_line("test21")
  end)

  it("can filter with ignorecase", function()
    helper.set_lines([[
test1
TEST2
test2
test3]])

    thetto.start("line", {opts = {ignorecase = true}})
    helper.sync_input({"test2"})

    thetto.execute("move_to_list")

    assert.current_line("TEST2")
  end)

  it("can filter with smartcase", function()
    helper.set_lines([[
TEST1
test1
hoge]])

    thetto.start("line", {opts = {smartcase = true}})
    helper.sync_input({"t"})

    thetto.execute("move_to_list")

    assert.exists_pattern("TEST1")
    assert.exists_pattern("test1")
    assert.no.exists_pattern("hoge")

    thetto.execute("move_to_input")

    vim.cmd("normal! dd")
    helper.sync_input({"TE"})

    thetto.execute("move_to_list")

    assert.exists_pattern("TEST1")
    assert.no.exists_pattern("test1")
    assert.no.exists_pattern("hoge")
  end)

  it("should show an error message if not found source", function()
    thetto.start("invalid")
    assert.exists_message("not found source: invalid")
    assert.window_count(1)
  end)

  it("should show an error message if not found action", function()
    thetto.start("line")
    thetto.execute("invalid")
    assert.exists_message("not found action: invalid")
  end)

  it("cannot execute open if there is no items", function()
    thetto.start("line")
    helper.sync_input({"hoge"})
    thetto.execute("open")
    assert.exists_message("not found action: open")
  end)

  it("can resume with offset", function()
    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line")
    thetto.execute("quit")

    thetto.resume_execute({opts = {offset = -1}})
    assert.current_line("test1")

    thetto.resume_execute({opts = {offset = 1}})
    assert.window_count(1)
    assert.current_line("test2")

    thetto.resume_execute({opts = {offset = 1}})
    assert.window_count(1)
    assert.current_line("test3")

    thetto.resume_execute({opts = {offset = 1}})
    assert.current_line("test3")
  end)

  it("can custom source global options", function()
    thetto.setup({source = {line = {global_opts = {insert = false}}}})

    helper.set_lines([[
test1
test2]])

    thetto.start("line")

    assert.current_line("test1")
  end)

  it("can custom source action", function()
    local called = false
    thetto.setup({
      source_actions = {
        line = {
          action_hoge = function(_)
            called = true
          end,
        },
      },
    })

    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line", {opts = {action = "hoge"}})
    thetto.execute()

    assert.is_true(called)
  end)

  it("can custom kind action", function()
    local called = false

    thetto.setup({
      kind_actions = {
        ["file/directory"] = {
          action_hoge = function(_)
            called = true
          end,
        },
      },
    })

    helper.set_lines([[
test1
test2
test3]])

    thetto.start("vim/runtimepath", {opts = {action = "hoge"}})
    thetto.execute()

    assert.is_true(called)
  end)

  it("can input lua escape character", function()
    helper.set_lines([[
test1
test%
test3]])

    thetto.start("line")
    helper.sync_input({"%"})

    thetto.execute("move_to_list")

    assert.current_line("test%")
  end)

  it("can execute debug_print", function()
    helper.set_lines([[
test1
test2]])

    thetto.start("line")

    thetto.execute("debug_print")

    assert.exists_message("row = 1")
    assert.exists_message("value = \"test1\"")
  end)

  it("can select items and execute action", function()
    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line", {opts = {insert = false}})

    thetto.execute("toggle_selection")
    vim.cmd("normal! j")
    thetto.execute("toggle_selection")
    vim.cmd("normal! j")

    thetto.execute("toggle_selection")
    thetto.execute("toggle_selection")

    thetto.execute("tab_open")

    assert.tab_count(3)
    assert.current_line("test2")
  end)

  it("can execute toggle_all_selection", function()
    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line", {opts = {insert = false}})

    helper.search("test2")
    thetto.execute("toggle_selection")

    thetto.execute("toggle_all_selection")

    thetto.execute("tab_open")

    assert.tab_count(3)
    assert.current_line("test3")
    vim.cmd("tabclose")
    assert.current_line("test1")
  end)

  it("stops the unfinished job on closed", function()
    local job = require("thetto.lib.job").new({"sleep", "9"}, {})
    require("thetto.handler.source.line").collect = function(_)
      return {}, job
    end

    thetto.start("line", {opts = {insert = false}})
    thetto.execute("quit")

    assert.is_false(job:is_running())
  end)

  it("can execute yank", function()
    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line", {opts = {insert = false}})

    vim.cmd("normal! vj")
    thetto.execute("yank")

    assert.register_value("+", "test1\ntest2")
  end)

  it("can open with action opts", function()
    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line", {opts = {insert = false}, action_opts = {register = 1}})
    helper.search("test3")

    thetto.execute("yank")

    assert.register_value("1", "test3")
  end)

  it("can execute append", function()
    helper.set_lines([[
test1
test2
test3]])
    vim.cmd("normal! $")

    thetto.start("line", {opts = {insert = false}})
    helper.search("test2")

    thetto.execute("append")

    assert.current_line("test1test2")
  end)

  it("can use sorters", function()
    helper.set_lines([[
te
t
test
tes]])

    thetto.start("line", {opts = {insert = false, sorters = {"length"}}})

    assert.current_line("t")
    vim.cmd("normal! j")
    assert.current_line("te")
    vim.cmd("normal! j")
    assert.current_line("tes")
  end)

  it("does not open windows if no items", function()
    thetto.start("cmd/ctags")
    assert.exists_message("cmd/ctags: empty")
    assert.window_count(1)

    thetto.start("cmd/ctags")
    -- should be the same error
    assert.exists_message("cmd/ctags: empty")
  end)

  it("can custom default opts", function()
    thetto.setup({global_opts = {display_limit = 1}})

    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line", {opts = {insert = false}})

    assert.line_count(1)
  end)

  it("can add filter", function()
    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line")
    thetto.execute("add_filter", {action_opts = {name = "-substring"}})

    vim.cmd("normal! G")
    helper.sync_input({"test2"})

    thetto.execute("move_to_list")

    assert.exists_pattern("test1")
    assert.exists_pattern("test3")
  end)

  it("can remove filter", function()
    thetto.setup({source = {line = {filters = {"substring", "-substring"}}}})

    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line")

    vim.cmd("normal! G")
    helper.sync_input({"test2"})

    helper.wait_ui(function()
      thetto.execute("remove_filter", {action_opts = {name = "-substring"}})
    end)
    thetto.execute("move_to_list")

    assert.exists_pattern("test2")
  end)

  it("can inverse filter", function()
    thetto.setup({filters = {"-substring"}})

    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line")
    helper.sync_input({"test2"})

    thetto.execute("inverse_filter")

    assert.exists_pattern("test2")
  end)

  it("can change filter", function()
    thetto.setup({filters = {"substring"}})

    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line")
    helper.sync_input({"test2"})

    helper.wait_ui(function()
      thetto.execute("change_filter", {action_opts = {name = "-substring"}})
    end)
    thetto.execute("move_to_list")

    assert.no.exists_pattern("test2")
  end)

  it("cannot remove the last filter", function()
    thetto.start("line")

    thetto.execute("remove_filter")
    assert.exists_message("the last filter cannot be removed")
  end)

  it("cannot delete input lines", function()
    thetto.setup({filters = {"substring", "-substring"}})

    thetto.start("line")
    helper.wait_ui(function()
      vim.cmd("normal! dd")
    end)

    assert.line_count(2)
  end)

  it("can reverse sorter", function()
    thetto.setup({sorters = {"length"}})

    helper.set_lines([[
te
t
tes]])

    thetto.start("line", {opts = {insert = false}})
    assert.current_line("t")

    helper.wait_ui(function()
      thetto.execute("reverse_sorter")
    end)

    assert.current_line("tes")
  end)

  it("can reverse specified sorter", function()
    thetto.setup({sorters = {"length", "row"}})

    helper.set_lines([[
te
t
tes]])

    thetto.start("line", {opts = {insert = false}})
    assert.current_line("t")

    helper.wait_ui(function()
      thetto.execute("reverse_sorter", {action_opts = {name = "length"}})
    end)

    assert.current_line("tes")
  end)

  it("can add sorter by toggle_sorter", function()
    helper.set_lines([[
te
t
tes]])

    thetto.start("line", {opts = {insert = false}})

    helper.wait_ui(function()
      thetto.execute("toggle_sorter", {action_opts = {name = "length"}})
    end)

    assert.current_line("t")
  end)

  it("can remove sorter by toggle_sorter", function()
    thetto.setup({sorters = {"length"}})

    helper.set_lines([[
te
t
tes]])

    thetto.start("line", {opts = {insert = false}})

    helper.wait_ui(function()
      thetto.execute("toggle_sorter", {action_opts = {name = "length"}})
    end)

    assert.current_line("te")
  end)

  it("can move to input with behavior as `i`", function()
    thetto.setup({filters = {"substring", "-substring"}})

    thetto.start("line")
    helper.sync_input({"hoge"})

    thetto.execute("move_to_list")
    thetto.execute("move_to_input")

    assert.current_column(#("hoge"))
  end)

  it("can move to input with behavior as `a`", function()
    thetto.setup({filters = {"substring", "-substring"}})

    thetto.start("line")
    helper.sync_input({"hoge"})

    thetto.execute("move_to_list")
    thetto.execute("move_to_input", {action_opts = {behavior = "a"}})

    assert.current_column(#("hoge") + 1)
  end)

  it("can filter by regex", function()
    thetto.setup({filters = {"regex"}})

    helper.set_lines([[
test1
test2
test3]])

    thetto.start("line")
    helper.sync_input({"2$"})

    thetto.execute("move_to_list")

    assert.exists_pattern("test2")
  end)

  it("can execute action with range", function()
    helper.set_lines([[
test1
test2
test3
test4
test5]])

    thetto.start("line", {opts = {insert = false}})

    vim.cmd("2")
    vim.cmd("normal! v2j")
    thetto.execute("toggle_selection")
    thetto.execute("tab_open")

    assert.tab_count(4)
  end)

  it("closes ui completely", function()
    thetto.start("line")
    vim.cmd("buffer #")
    vim.cmd("close")

    assert.window_count(1)
  end)

  it("can resume current window", function()
    helper.set_lines([[
test1
test2]])

    thetto.start("line")
    thetto.execute("move_to_list")
    thetto.execute("quit")
    thetto.resume()

    assert.exists_pattern("test1")
  end)

  it("can open and close preview", function()
    helper.set_lines([[
test1
test2]])

    thetto.start("line", {opts = {insert = false}})
    local count = helper.window_count()

    thetto.execute("preview")
    assert.window_count(count + 1)

    thetto.execute("close_preview")
    assert.window_count(count)
  end)

  it("can toggle preview", function()
    helper.set_lines([[
test1
test2]])

    thetto.start("line", {opts = {insert = false}})
    local count = helper.window_count()

    thetto.execute("toggle_preview")
    assert.window_count(count + 1)

    thetto.execute("toggle_preview")
    assert.window_count(count)
  end)

  it("toggle_preview can execute continuously", function()
    helper.set_lines([[
test1
test2]])

    thetto.start("line", {opts = {insert = false}})
    local count = helper.window_count()

    thetto.execute("toggle_preview")
    assert.window_count(count + 1)

    vim.cmd("normal! j")
    thetto.execute("toggle_preview")
    assert.window_count(count + 1)
  end)

  it("can focus only input or list", function()
    helper.set_lines([[
test1
test2]])

    thetto.start("line")

    for _, window in ipairs(helper.sub_windows()) do
      vim.fn.win_gotoid(window)
      assert.no.filetype("")
    end
  end)

  it("can execute action automatically", function()
    local value = nil
    thetto.setup({
      source_actions = {
        line = {
          action_hoge = function(_, items)
            value = items[1].value
          end,
          behaviors = {hoge = {quit = false}},
        },
      },
    })

    helper.set_lines([[
test_auto_1
test_auto_2]])

    thetto.start("line", {opts = {auto = "hoge", insert = false}})
    assert.equals("test_auto_1", value)

    thetto.execute("move_to_input")
    helper.sync_input({"test_auto_2"})

    assert.equals("test_auto_2", value)
  end)

  it("can use visual mode even if enabled auto action", function()
    thetto.setup({
      source_actions = {
        line = {
          action_hoge = function(_, _)
            vim.cmd("normal! " .. vim.api.nvim_eval("\"\\<ESC>\""))
          end,
          behaviors = {hoge = {quit = false}},
        },
      },
    })

    helper.set_lines([[
test_auto_1
test_auto_2]])

    thetto.start("line", {opts = {auto = "hoge", insert = false}})

    vim.cmd("normal! Vj")
    vim.cmd("doautocmd CursorMoved")

    thetto.execute("toggle_selection")
    thetto.execute("tab_open")

    assert.tab_count(3)
  end)

  it("action shows error if it is executed on empty", function()
    thetto.start("line")
    helper.sync_input({"hoge"})

    thetto.execute("open")
    assert.exists_message("not found action: open")
  end)

  it("can resume previous source", function()
    helper.set_lines([[
test1
test2]])

    thetto.start("line", {opts = {insert = false}})
    helper.search("test2")

    thetto.start("thetto/source")
    thetto.execute("resume_previous")
    thetto.execute("open")

    assert.current_line("test2")
  end)

  it("can resume wrapped previous source", function()
    helper.set_lines([[
test1
test2]])

    thetto.start("thetto/source", {opts = {insert = false}})
    thetto.execute("quit")

    thetto.start("line", {opts = {insert = false}})
    helper.search("test2")

    thetto.execute("resume_previous")
    assert.exists_pattern("^line$")

    thetto.execute("resume_previous")
    thetto.execute("open")

    assert.current_line("test2")
  end)

  it("can resume next source", function()
    helper.set_lines([[
test1
test2]])

    thetto.start("thetto/source")
    thetto.execute("quit")

    thetto.start("line", {opts = {insert = false}})
    helper.search("test2")

    thetto.execute("resume_previous")
    thetto.execute("resume_next")
    thetto.execute("open")

    assert.current_line("test2")
  end)

  it("can resume wrapped next source", function()
    helper.set_lines([[
test1
test2]])

    thetto.start("line", {opts = {insert = false}})
    helper.search("test2")

    thetto.start("thetto/source")
    thetto.execute("resume_next")
    thetto.execute("open")

    assert.current_line("test2")
  end)

end)
