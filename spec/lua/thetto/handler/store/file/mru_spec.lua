local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")
local store = helper.require("thetto.core.store")

describe("file/mru store", function()
  local store_file_path
  before_each(function()
    helper.before_each()
    helper.new_file("store.txt")
    store_file_path = helper.test_data_dir .. "store"
  end)

  after_each(function()
    store.Store.get("file/mru"):quit()
    helper.after_each()
  end)

  it("can store mru file paths", function()
    helper.new_file("file1")
    helper.new_file("file2")

    thetto.setup_store("file/mru", { file_path = store_file_path })
    vim.cmd("edit file1")
    vim.cmd("edit file2")

    local data = store.Store.get("file/mru"):data()

    assert.equals(helper.test_data_dir .. "file2", data[1])
    assert.equals(helper.test_data_dir .. "file1", data[2])

    store.Store.get("file/mru"):save()

    local f = io.open(store_file_path)
    local content = vim.fn.split(f:read("*a"), "\n", false)
    assert.is_same(vim.fn.reverse(data), content)
  end)
end)
