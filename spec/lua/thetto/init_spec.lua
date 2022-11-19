local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

local test_source1 = "test_values1"
local test_source2 = "test_values2"
local test_items1
local test_items2

before_each(function()
  test_items1 = {
    "test1",
    "test2",
  }
  test_items2 = {
    "test1",
    "test2",
  }

  thetto.register_source(test_source1, {
    collect = function()
      return vim.tbl_map(function(item)
        if type(item) == "string" then
          return { value = item }
        end
        return item
      end, test_items1)
    end,
  })
  thetto.register_source(test_source2, {
    collect = function()
      return vim.tbl_map(function(item)
        if type(item) == "string" then
          return { value = item }
        end
        return item
      end, test_items2)
    end,
  })
end)

describe("thetto", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can open ui in list buffer", function()
    thetto.start(test_source1, { opts = { insert = false } })

    assert.filetype("thetto")
  end)

  it("can open ui in input buffer", function()
    thetto.start(test_source1)

    assert.filetype("thetto-input")
  end)

  it("can scroll ui by offset", function()
    test_items1 = {
      "test1",
      "test2",
      "test3",
    }

    helper.sync_start(test_source1, { opts = { insert = false, offset = 10 } })

    assert.current_line("test3")
  end)

  it("can scroll ui by search_offset", function()
    test_items1 = {
      "test1",
      "test2",
      "test3",
    }

    helper.sync_start(test_source1, {
      opts = {
        insert = false,
        search_offset = function(item)
          return item.value == "test2"
        end,
      },
    })

    assert.current_line("test2")
  end)

  it("can close ui by :quit", function()
    thetto.start(test_source1, { opts = { insert = false } })
    vim.cmd.quit()

    assert.window_count(1)
  end)

  it("should exist only one in a tab", function()
    thetto.start(test_source1)
    thetto.start(test_source2)

    assert.window_count(4)
  end)

  it("should exist same source only one", function()
    thetto.start(test_source1)
    vim.cmd.tabedit()
    thetto.start(test_source1)

    assert.window_count(4)
  end)

  it("can filter by substring #slow", function()
    thetto.setup({ sorters = { "length" } })

    thetto.start(test_source1)
    helper.sync_input({ "2" })

    thetto.execute("move_to_list")

    assert.current_line("test2")
    assert.no.exists_pattern("test1")
  end)

  it("can filter with ignorecase #slow", function()
    test_items1 = {
      "test1",
      "TEST2",
      "test2",
      "test3",
    }

    thetto.start(test_source1, { opts = { ignorecase = true } })
    helper.sync_input({ "test2" })

    thetto.execute("move_to_list")

    assert.current_line("TEST2")
  end)

  it("can filter with smartcase #slow", function()
    test_items1 = {
      "TEST1",
      "test1",
      "hoge",
    }

    thetto.start(test_source1, { opts = { smartcase = true } })
    helper.sync_input({ "t" })

    thetto.execute("move_to_list")

    assert.exists_pattern("TEST1")
    assert.exists_pattern("test1")
    assert.no.exists_pattern("hoge")

    thetto.execute("move_to_input")

    vim.cmd.normal({ args = { "dd" }, bang = true })
    helper.sync_input({ "TE" })

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

  it("can input lua escape character #slow", function()
    test_items1 = {
      "test1",
      "test%",
      "test3",
    }

    thetto.start(test_source1)
    helper.sync_input({ "%" })

    thetto.execute("move_to_list")

    assert.current_line("test%")
  end)

  it("can open with action opts #slow", function()
    test_items1 = {
      "test1",
      "test2",
      "test3",
    }

    thetto.start(test_source1, { opts = { insert = false }, action_opts = { register = 1 } })
    helper.search("test3")

    thetto.execute("yank")

    assert.register_value("1", "test3")
  end)

  it("can use sorters", function()
    test_items1 = {
      "te",
      "t",
      "test",
      "tes",
    }

    thetto.start(test_source1, { opts = { insert = false, sorters = { "length" } } })

    assert.current_line("t")
    vim.cmd.normal({ args = { "j" }, bang = true })
    assert.current_line("te")
    vim.cmd.normal({ args = { "j" }, bang = true })
    assert.current_line("tes")
  end)

  it("can set input lines", function()
    test_items1 = {
      "hoge",
      "test",
    }

    thetto.start(test_source1, { opts = { insert = false, input_lines = { "test" } } })

    assert.current_line("test")
  end)

  it("does not open windows if no items", function()
    local source = "no_values_test"
    thetto.register_source(source, {
      collect = function()
        return {}
      end,
    })

    helper.sync_start(source)
    assert.exists_message(source .. ": empty")
    assert.window_count(1)

    helper.sync_start(source)
    -- should be the same error
    assert.exists_message(source .. ": empty")
  end)

  it("cannot delete input lines #slow", function()
    thetto.setup({ filters = { "substring", "-substring" } })

    helper.sync_start(test_source1)

    vim.cmd.normal({ args = { "dd" }, bang = true })
    helper.wait_redraw()

    assert.line_count(2)
  end)

  it("can move to input with behavior as `i` #slow", function()
    thetto.setup({ filters = { "substring", "-substring" } })

    helper.sync_start(test_source1)
    helper.sync_input({ "hoge" })

    helper.sync_execute("move_to_list")
    helper.sync_execute("move_to_input")

    assert.cursor_column(#"hoge")
  end)

  it("can move to input with behavior as `a` #slow", function()
    thetto.setup({ filters = { "substring", "-substring" } })

    thetto.start(test_source1)
    helper.sync_input({ "hoge" })

    thetto.execute("move_to_list")
    thetto.execute("move_to_input", { action_opts = { behavior = "a" } })

    assert.cursor_column(#"hoge" + 1)
  end)

  it("can filter by regex #slow", function()
    thetto.setup({ filters = { "regex" } })

    thetto.start(test_source1)
    helper.sync_input({ "2$" })

    thetto.execute("move_to_list")

    assert.exists_pattern("test2")
  end)

  it("can use function as filters", function()
    thetto.start(test_source1, {
      opts = {
        insert = false,
        input_lines = { "", "test2" },
        filters = function()
          return { "-substring", "substring" }
        end,
      },
    })

    assert.exists_pattern("test2")
  end)

  it("closes ui completely", function()
    thetto.start(test_source1)
    vim.cmd.buffer("#")
    vim.cmd.close()

    assert.window_count(1)
  end)

  it("can focus only input or list", function()
    thetto.start(test_source1)

    for _, window in ipairs(helper.sub_windows()) do
      vim.fn.win_gotoid(window)
      assert.no.filetype("")
    end
  end)

  it("can execute action automatically #slow", function()
    local value = nil
    thetto.setup({
      source_actions = {
        [test_source1] = {
          action_hoge = function(items)
            value = items[1].value
          end,
          behaviors = { hoge = { quit = false } },
        },
      },
    })

    test_items1 = {
      "test_auto_1",
      "test_auto_2",
    }

    thetto.start(test_source1, { opts = { auto = "hoge", insert = false } })
    helper.wait_redraw()
    assert.equals("test_auto_1", value)

    thetto.execute("move_to_input")
    helper.sync_input({ "test_auto_2" })

    assert.equals("test_auto_2", value)
  end)

  it("can use visual mode even if enabled auto action", function()
    thetto.setup({
      source_actions = {
        [test_source1] = {
          action_hoge = function(_, _)
            vim.cmd.normal({ args = { vim.api.nvim_eval('"\\<ESC>"') }, bang = true })
          end,
          behaviors = { hoge = { quit = false } },
        },
      },
    })

    thetto.start(test_source1, { opts = { auto = "hoge", insert = false } })

    vim.cmd.normal({ args = { "Vj" }, bang = true })
    vim.api.nvim_exec_autocmds("CursorMoved", {})

    thetto.execute("toggle_selection")
    thetto.execute("append")

    assert.current_line("test1test2")
  end)

  it("can return function result", function()
    local source = "test_function"
    thetto.register_source(source, {
      collect = function()
        return function(observer)
          observer:next({
            { value = "test1" },
          })
          observer:complete()
        end
      end,
    })

    thetto.start(source, { opts = { insert = false } })

    assert.exists_pattern("test1")
  end)

  it("can set source specific setting", function()
    local called_source_name
    vim.api.nvim_create_autocmd({ "User" }, {
      pattern = { "ThettoOpened" },
      callback = function(args)
        called_source_name = args.data.source_name
      end,
    })

    thetto.start(test_source1, { opts = { insert = false } })

    assert.equal(test_source1, called_source_name)
  end)
end)

describe("thetto.reload()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("collects results again", function()
    local origin_window = vim.api.nvim_get_current_win()

    thetto.start(test_source1, { opts = { insert = false, input_lines = { "test2" } } })

    vim.api.nvim_set_current_win(origin_window)
    vim.cmd.wincmd("p")

    helper.sync_reload()

    thetto.execute("move_to_input")
    vim.cmd.delete({ reg = "_" })
    thetto.execute("move_to_list")

    assert.current_line("test2")
  end)
end)

describe("thetto.execute()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("should show an error message if not found action", function()
    thetto.start(test_source1)

    helper.sync_execute("invalid")

    assert.exists_message("not found action: invalid")
  end)

  it("shows error if items is empty because filtered #slow", function()
    thetto.start(test_source1)
    helper.sync_input({ "hoge" })

    helper.sync_execute("open")

    assert.exists_message("not found action: open")
  end)

  it("cannot execute open if there is no items #slow", function()
    thetto.start(test_source1)
    helper.sync_input({ "hoge" })

    helper.sync_execute("open")

    assert.exists_message("not found action: open")
  end)

  it("can use custom action as default", function()
    local called = false
    thetto.setup({
      kind_actions = {
        base = {
          action_hoge = function(_)
            called = true
          end,
        },
      },
      source = { [test_source1] = { global_opts = { action = "hoge" } } },
    })
    thetto.start(test_source1, { opts = { insert = false } })

    thetto.execute()

    assert.is_true(called)
  end)

  it("can have actions in source", function()
    local called = false
    local source_name = "has_actions"
    thetto.register_source(source_name, {
      collect = function()
        return {
          { value = "1" },
        }
      end,
      actions = {
        action_test = function()
          called = true
        end,
      },
    })

    thetto.start(source_name, { opts = { insert = false } })
    thetto.execute("test")

    assert.is_true(called)
  end)

  it("can custom default action by kind_actions", function()
    local called = false
    thetto.setup({
      kind_actions = {
        base = {
          action_hoge = function(_)
            called = true
          end,
          default_action = "hoge",
        },
      },
    })

    thetto.start(test_source1, { opts = { insert = false } })
    thetto.execute()

    assert.is_true(called)
  end)
end)

describe("thetto.setup()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can custom default opts", function()
    thetto.setup({ global_opts = { display_limit = 1 } })

    thetto.start(test_source1, { opts = { insert = false } })

    assert.line_count(1)
  end)

  it("can custom source global options", function()
    thetto.setup({ source = { [test_source1] = { global_opts = { insert = false } } } })

    thetto.start(test_source1)

    assert.current_line("test1")
  end)

  it("can custom source action", function()
    local called = false
    thetto.setup({
      source_actions = {
        [test_source1] = {
          action_hoge = function(_)
            called = true
          end,
        },
      },
    })

    thetto.start(test_source1, { opts = { action = "hoge" } })
    thetto.execute()

    assert.is_true(called)
  end)

  it("can set source alias", function()
    thetto.setup({
      source = {
        [test_source1] = { global_opts = { insert = true } },
        example_alias1 = { alias_to = test_source1 },
        example_alias2 = { alias_to = "example_alias1", global_opts = { insert = false } },
      },
    })

    thetto.start("example_alias2")

    assert.current_line("test1")
  end)

  it("can custom kind action", function()
    local called = false

    thetto.setup({
      kind_actions = {
        ["base"] = {
          action_hoge = function(_)
            called = true
          end,
        },
      },
    })

    test_items1 = {
      "test1",
      "test2",
      "test3",
    }

    thetto.start(test_source1, { opts = { action = "hoge" } })
    thetto.execute()

    assert.is_true(called)
  end)
end)

describe("thetto.resume()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can resume even if opened", function()
    helper.sync_start(test_source1)
    vim.cmd.tabedit()

    helper.sync_resume()
    assert.window_count(4)
  end)

  it("goes back to original window when quit resumed thetto", function()
    helper.sync_start(test_source1)
    vim.cmd.tabedit()
    local current = vim.api.nvim_get_current_win()

    helper.sync_resume()
    helper.sync_start(test_source1)
    helper.sync_execute("quit")

    assert.window_id(current)
  end)

  it("can resume latest #slow", function()
    test_items1 = {
      "test11",
      "test21",
      "test22",
    }

    thetto.start(test_source1)
    helper.sync_input({ "test2" })

    thetto.execute("move_to_list")
    vim.cmd.normal({ args = { "G" }, bang = true })

    thetto.execute("quit")
    thetto.resume()

    thetto.execute("move_to_input")

    assert.filetype("thetto-input")
    assert.current_line("test2")

    thetto.execute("move_to_list")

    assert.current_line("test22")
    vim.cmd.normal({ args = { "gg" }, bang = true })
    assert.current_line("test21")
  end)

  it("can resume by source #slow", function()
    test_items1 = {
      "test11",
      "test21",
      "test22",
    }

    helper.sync_start(test_source1)
    helper.sync_input({ "test2" })

    helper.sync_execute("quit")
    helper.sync_start(test_source2)
    helper.sync_execute("quit")
    helper.sync_resume(test_source1)

    assert.filetype("thetto-input")
    assert.current_line("test2")

    helper.sync_execute("move_to_list")

    assert.current_line("test21")
  end)

  it("can resume current window", function()
    helper.sync_start(test_source1)
    helper.sync_execute("move_to_list")
    helper.sync_execute("quit")
    helper.sync_resume()

    assert.exists_pattern("test1")
  end)

  it("can resume empty result", function()
    local source = "no_values_test"
    thetto.register_source(source, {
      collect = function()
        return {}
      end,
    })

    helper.sync_start(source, { opts = { insert = false } })

    helper.sync_resume()

    assert.current_line("")
  end)

  it("can resume source that is closed latest", function()
    test_items1 = {
      "resumed",
    }

    helper.sync_start(test_source1, { opts = { insert = false } })
    helper.sync_execute("quit")

    helper.sync_start(test_source2, { opts = { insert = false } })
    helper.sync_execute("quit")

    helper.sync_resume()
    helper.sync_execute("resume_previous")
    helper.sync_execute("quit")

    helper.sync_resume()

    assert.exists_pattern("resumed")
  end)

  it("can disable resume by can_resume=false", function()
    test_items1 = {
      "resumed",
    }

    helper.sync_start(test_source1, { opts = { insert = false } })
    helper.sync_execute("quit")

    helper.sync_start(test_source2, { opts = { insert = false, can_resume = false } })
    helper.sync_execute("quit")

    helper.sync_resume()

    assert.exists_pattern("resumed")
  end)
end)

describe("thetto.resume_execute()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can resume with offset", function()
    local item
    thetto.setup({
      kind_actions = {
        base = {
          action_hoge = function(items)
            item = items[1].value
          end,
        },
      },
    })

    test_items1 = {
      "test1",
      "test2",
      "test3",
    }

    thetto.start(test_source1)
    thetto.execute("quit")

    thetto.resume_execute({ action_name = "hoge", opts = { offset = -1 } })
    assert.equal("test1", item)

    thetto.resume_execute({ action_name = "hoge", opts = { offset = 1 } })
    assert.window_count(1)
    assert.equal("test2", item)

    thetto.resume_execute({ action_name = "hoge", opts = { offset = 1 } })
    assert.window_count(1)
    assert.equal("test3", item)

    thetto.resume_execute({ action_name = "hoge", opts = { offset = 1 } })
    assert.equal("test3", item)
  end)
end)

describe("thetto.get()", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can get current item", function()
    thetto.start(test_source1, { opts = { insert = false } })
    local items = thetto.get()

    assert.is_same({ { index = 1, value = "test1" } }, items)
  end)
end)

describe("resume_previous action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can resume previous source", function()
    local test_source3 = "_test_values3"
    thetto.register_source(test_source3, {
      collect = function()
        return { { value = "test5" } }
      end,
    })

    thetto.start(test_source1, { opts = { insert = false } })
    helper.search("test2")

    test_items2 = {
      "test3",
      "test4",
    }

    thetto.start(test_source2, { opts = { insert = false } })
    helper.search("test4")

    thetto.start(test_source3, { opts = { insert = false } })

    thetto.execute("resume_previous")
    thetto.execute("resume_previous")

    assert.current_line("test2")
  end)

  it("can resume wrapped previous source", function()
    test_items2 = {
      "test3",
      "test4",
    }

    thetto.start(test_source2, { opts = { insert = false } })
    thetto.execute("quit")

    thetto.start(test_source1, { opts = { insert = false } })
    helper.search("test2")

    thetto.execute("resume_previous")
    assert.exists_pattern("test3")

    thetto.execute("resume_previous")
    thetto.execute("append")

    assert.current_line("test2")
  end)
end)

describe("resume_next action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can resume next source", function()
    test_items2 = {
      "test3",
      "test4",
    }

    thetto.start(test_source2)
    thetto.execute("quit")

    thetto.start(test_source1, { opts = { insert = false } })
    helper.search("test2")

    thetto.execute("resume_previous")
    thetto.execute("resume_next")
    thetto.execute("append")

    assert.current_line("test2")
  end)

  it("can resume wrapped next source", function()
    test_items2 = {
      "test3",
      "test4",
    }

    thetto.start(test_source1, { opts = { insert = false } })
    helper.search("test2")

    thetto.start(test_source2)
    thetto.execute("resume_next")
    thetto.execute("append")

    assert.current_line("test2")
  end)
end)

describe("remove_filter action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can remove filter #slow", function()
    thetto.setup({ source = { [test_source1] = { filters = { "substring", "-substring" } } } })

    thetto.start(test_source1)

    vim.cmd.normal({ args = { "G" }, bang = true })
    helper.sync_input({ "test2" })

    thetto.execute("remove_filter", { action_opts = { name = "-substring" } })
    thetto.execute("move_to_list")

    assert.exists_pattern("test2")
  end)

  it("cannot remove the last filter", function()
    helper.sync_start(test_source1)

    helper.sync_execute("remove_filter")
    assert.exists_message("the last filter cannot be removed")
  end)
end)

describe("reverse action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can reverse items", function()
    test_items1 = {
      "1",
      "2",
      "3",
    }

    helper.sync_start(test_source1, { opts = { insert = false } })
    assert.current_line("1")

    helper.sync_execute("reverse")

    assert.current_line("3")
  end)

  it("can reset reversed", function()
    test_items1 = {
      "1",
      "2",
      "3",
    }

    helper.sync_start(test_source1, { opts = { insert = false } })
    assert.current_line("1")

    helper.sync_execute("reverse")
    helper.sync_execute("reverse")

    assert.current_line("1")
  end)
end)

describe("reverse_sorter action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can reverse sorter", function()
    thetto.setup({ sorters = { "length" } })

    test_items1 = {
      "te",
      "t",
      "tes",
    }

    helper.sync_start(test_source1, { opts = { insert = false } })
    assert.current_line("t")

    helper.sync_execute("reverse_sorter")

    assert.current_line("tes")
  end)

  it("can reverse specified sorter", function()
    thetto.setup({ sorters = { "length", "row" } })

    test_items1 = {
      "te",
      "t",
      "tes",
    }

    helper.sync_start(test_source1, { opts = { insert = false } })
    assert.current_line("t")

    helper.sync_execute("reverse_sorter", { action_opts = { name = "length" } })

    assert.current_line("tes")
  end)
end)

describe("add_filter action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can add filter #slow", function()
    test_items1 = {
      "test1",
      "test2",
      "test3",
    }

    thetto.start(test_source1)
    thetto.execute("add_filter", { action_opts = { name = "-substring" } })

    vim.cmd.normal({ args = { "G" }, bang = true })
    helper.sync_input({ "test2" })

    helper.sync_execute("move_to_list")

    assert.exists_pattern("test1")
    assert.exists_pattern("test3")
  end)
end)

describe("inverse_filter action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can inverse filter #slow", function()
    thetto.setup({ filters = { "-substring" } })

    test_items1 = {
      "test1",
      "test2",
      "test3",
    }

    thetto.start(test_source1)
    helper.sync_input({ "test2" })

    thetto.execute("inverse_filter")

    assert.exists_pattern("test2")
  end)
end)

describe("change_filter action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can change filter", function()
    thetto.setup({ filters = { "substring" } })

    test_items1 = {
      "test1",
      "test2",
      "test3",
    }

    thetto.start(test_source1)
    helper.sync_input({ "test2" })

    thetto.execute("change_filter", { action_opts = { name = "-substring" } })
    helper.wait_redraw()
    thetto.execute("move_to_list")

    assert.no.exists_pattern("test2")
  end)
end)

describe("toggle_sorter action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can add sorter by toggle_sorter", function()
    test_items1 = {
      "te",
      "t",
      "tes",
    }

    helper.sync_start(test_source1, { opts = { insert = false } })
    helper.sync_execute("toggle_sorter", { action_opts = { name = "length" } })

    assert.current_line("t")
  end)

  it("can remove sorter by toggle_sorter", function()
    thetto.setup({ sorters = { "length" } })

    test_items1 = {
      "te",
      "t",
      "tes",
    }

    helper.sync_start(test_source1, { opts = { insert = false } })
    helper.sync_execute("toggle_sorter", { action_opts = { name = "length" } })

    assert.current_line("te")
  end)
end)

describe("debug_print action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can execute debug_print", function()
    thetto.start(test_source1)

    thetto.execute("debug_print")

    assert.exists_message('value = "test1"')
  end)
end)

describe("toggle_selection action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can select items and execute action", function()
    test_items1 = {
      "test1",
      "test2",
      "test3",
    }

    thetto.start(test_source1, { opts = { insert = false } })

    thetto.execute("toggle_selection")
    vim.cmd.normal({ args = { "j" }, bang = true })
    thetto.execute("toggle_selection")
    vim.cmd.normal({ args = { "j" }, bang = true })

    thetto.execute("toggle_selection")
    thetto.execute("toggle_selection")

    thetto.execute("append")

    assert.current_line("test1test2")
  end)

  it("can execute with range", function()
    test_items1 = {
      "test1",
      "test2",
      "test3",
      "test4",
      "test5",
    }

    thetto.start(test_source1, { opts = { insert = false } })

    vim.cmd.normal({ args = { "2gg" }, bang = true })
    vim.cmd.normal({ args = { "v2j" }, bang = true })
    thetto.execute("toggle_selection")
    thetto.execute("append")

    assert.current_line("test2test3test4")
  end)
end)

describe("toggle_all_selection action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can execute toggle_all_selection", function()
    test_items1 = {
      "test1",
      "test2",
      "test3",
    }

    thetto.start(test_source1, { opts = { insert = false } })

    helper.search("test2")
    thetto.execute("toggle_selection")

    thetto.execute("toggle_all_selection")

    thetto.execute("append")

    assert.current_line("test1test3")
  end)
end)

describe("append action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can execute append", function()
    thetto.start(test_source1, { opts = { insert = false } })
    helper.search("test2")

    thetto.execute("append")

    assert.current_line("test2")
  end)
end)

describe("yank action #slow", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can yank item value", function()
    test_items1 = {
      "test1",
      "test2",
      "test3",
    }

    thetto.start(test_source1, { opts = { insert = false } })

    vim.cmd.normal({ args = { "vj" }, bang = true })
    thetto.execute("yank")

    assert.register_value("+", "test1\ntest2")
  end)
end)

describe("toggle_preview action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can toggle preview", function()
    thetto.setup({
      kind_actions = {
        base = {
          action_preview = function(items, _, ctx)
            return nil, ctx.ui:open_preview(items[1], { lines = { items[1].value } })
          end,
        },
      },
    })

    thetto.start(test_source1, { opts = { insert = false, auto = "" } })
    local count = helper.window_count()

    thetto.execute("toggle_preview")
    assert.window_count(count + 1)

    thetto.execute("toggle_preview")
    assert.window_count(count)
  end)

  it("can execute continuously", function()
    thetto.setup({
      kind_actions = {
        base = {
          action_preview = function(items, _, ctx)
            return nil, ctx.ui:open_preview(items[1], { lines = { items[1].value } })
          end,
        },
      },
    })

    thetto.start(test_source1, { opts = { insert = false, auto = "" } })
    local count = helper.window_count()

    thetto.execute("toggle_preview")
    assert.window_count(count + 1)

    vim.cmd.normal({ args = { "j" }, bang = true })
    thetto.execute("toggle_preview")
    assert.window_count(count + 1)
  end)
end)

describe("preview action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can open preview", function()
    thetto.setup({
      kind_actions = {
        base = {
          action_preview = function(items, _, ctx)
            return nil, ctx.ui:open_preview(items[1], { lines = { items[1].value } })
          end,
        },
      },
    })

    thetto.start(test_source1, { opts = { insert = false, auto = "" } })
    local count = helper.window_count()

    thetto.execute("preview")
    assert.window_count(count + 1)
  end)
end)

describe("close_preview action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can close preview", function()
    thetto.start(test_source1, { opts = { insert = false } })
    local count = helper.window_count()

    thetto.execute("preview")
    thetto.execute("close_preview")

    assert.window_count(count)
  end)
end)

describe("move_to_input action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can move to filter", function()
    thetto.start(test_source1, { opts = { insert = false } })
    assert.filetype("thetto")

    thetto.execute("move_to_input")

    assert.filetype("thetto-input")
  end)
end)

describe("move_to_list action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can move to list", function()
    thetto.start(test_source1)
    assert.filetype("thetto-input")

    thetto.execute("move_to_list")

    assert.filetype("thetto")
  end)

  it("can move to list even if empty #slow", function()
    thetto.start(test_source1)
    helper.sync_input({ "test" })
    assert.filetype("thetto-input")

    thetto.execute("move_to_list")

    assert.filetype("thetto")
  end)
end)

describe("go_to_next_page action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can go to next page", function()
    test_items1 = {
      "test1",
      "test2",
      "test3",
      "test4",
    }

    thetto.start(test_source1, {
      opts = { display_limit = 2, insert = false },
    })

    thetto.execute("go_to_next_page")

    assert.current_line("test3")
  end)

  it("does nothing if current page is the last", function()
    thetto.start(test_source1, { opts = { insert = false } })

    thetto.execute("go_to_next_page")

    assert.current_line("test1")
  end)
end)

describe("go_to_previous_page action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can go to previous page", function()
    test_items1 = {
      "test1",
      "test2",
      "test3",
      "test4",
    }

    thetto.start(test_source1, {
      opts = { display_limit = 2, insert = false },
    })

    thetto.execute("go_to_next_page")
    thetto.execute("go_to_previous_page")

    assert.current_line("test1")
  end)

  it("does nothing if current page is the first", function()
    thetto.start(test_source1, { opts = { insert = false } })

    thetto.execute("go_to_previous_page")

    assert.current_line("test1")
  end)
end)

describe("change_display_limit action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can increase display limit", function()
    test_items1 = {
      "test1",
      "test2",
      "test3",
      "test4",
    }

    thetto.start(test_source1, {
      opts = { display_limit = 2, insert = false },
    })

    thetto.execute("change_display_limit", { action_opts = { offset = 1 } })

    assert.exists_pattern("test3")
    assert.no.exists_pattern("test4")
  end)
end)

describe("append_filter_input action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can append item value as filter input", function()
    thetto.start(test_source1)

    thetto.execute("append_filter_input")

    assert.current_line("test1")
  end)

  it("can concat item value as filter input", function()
    thetto.start(test_source1, { opts = { input_lines = { "test" } } })

    thetto.execute("append_filter_input")

    assert.current_line("test1")
  end)
end)

describe("recall_previous_history action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("does nothing if there is no history", function()
    thetto.start(test_source1)

    thetto.execute("recall_previous_history")

    assert.current_line("")
  end)

  it("recalls previous history", function()
    thetto.start(test_source1, { opts = { input_lines = { "test" } } })

    thetto.execute("quit")

    thetto.start(test_source1)
    thetto.execute("recall_previous_history")

    assert.current_line("test")
  end)
end)

describe("recall_next_history action", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  it("does nothing if there is no history", function()
    thetto.start(test_source1)

    thetto.execute("recall_next_history")

    assert.current_line("")
  end)

  it("recalls next history", function()
    thetto.start(test_source1, { opts = { input_lines = { "test1" } } })
    thetto.execute("quit")

    thetto.start(test_source1, { opts = { input_lines = { "test2" } } })
    thetto.execute("quit")

    thetto.start(test_source1)

    thetto.execute("recall_previous_history")
    assert.current_line("test2")

    thetto.execute("recall_previous_history")
    assert.current_line("test1")

    thetto.execute("recall_next_history")
    assert.current_line("test2")
  end)

  it("saves the first input", function()
    thetto.start(test_source1, { opts = { input_lines = { "test" } } })

    thetto.execute("recall_next_history")
    thetto.execute("recall_previous_history")

    assert.current_line("test")
  end)
end)
