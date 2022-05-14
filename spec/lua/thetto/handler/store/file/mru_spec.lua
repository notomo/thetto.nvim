local helper = require("thetto.lib.testlib.helper")
local thetto = helper.require("thetto")
local store = helper.require("thetto.core.store")

describe("file/mru store", function()
  local store_file_path
  before_each(function()
    helper.before_each()
    helper.test_data:create_file("store.txt")
    store_file_path = helper.test_data.full_path .. "store"
  end)

  after_each(function()
    store.get("file/mru"):quit()
    helper.after_each()
  end)

  it("can store mru file paths", function()
    helper.test_data:create_file("file1")
    helper.test_data:create_file("file2")

    thetto.setup_store("file/mru", { file_path = store_file_path })
    vim.cmd("edit file1")
    vim.cmd("edit file2")

    local data = store.get("file/mru"):data()

    assert.equals(helper.test_data.full_path .. "file2", data[1])
    assert.equals(helper.test_data.full_path .. "file1", data[2])

    store.get("file/mru"):save()

    local f = io.open(store_file_path)
    local content = vim.fn.split(f:read("*a"), "\n", false)
    assert.is_same(vim.fn.reverse(data), content)
  end)
end)
