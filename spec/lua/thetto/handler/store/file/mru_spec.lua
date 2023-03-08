local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")
local store = helper.require("thetto.core.store")

describe("file/mru store", function()
  local store_file_path
  before_each(function()
    helper.before_each()
    store_file_path = helper.test_data:create_file("store.txt")
  end)

  after_each(helper.after_each)

  it("can store mru file paths", function()
    local file_path1 = helper.test_data:create_file("file1")
    local file_path2 = helper.test_data:create_file("file2")

    thetto.setup_store("file/mru", { file_path = store_file_path })
    vim.cmd.edit("file1")
    vim.cmd.edit("file2")

    local data = store.get("file/mru"):data()

    assert.equals(file_path2, data[1])
    assert.equals(file_path1, data[2])

    store.get("file/mru"):save()

    local f = io.open(store_file_path)
    local content = vim.fn.split(f:read("*a"), "\n", false)
    assert.is_same(vim.fn.reverse(data), content)
  end)
end)
