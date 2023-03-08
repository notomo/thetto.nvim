local helper = require("thetto.test.helper")
local thetto = helper.require("thetto")

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

    thetto.setup_store("file/mru", {
      file_path = store_file_path,
      save_events = { "TabNew" },
    })
    vim.cmd.edit("file1")
    vim.cmd.edit("file2")
    vim.cmd.tabedit()

    local f = io.open(store_file_path)
    local content = vim.fn.split(f:read("*a"), "\n", false)
    f:close()
    local want = {
      file_path1,
      file_path2,
    }
    assert.is_same(want, content)
  end)
end)
