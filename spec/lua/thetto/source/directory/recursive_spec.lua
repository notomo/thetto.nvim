local helper = require("thetto/lib/testlib/helper")
local thetto = helper.require("thetto")

describe("directory/recursive source", function()

  before_each(function()
    helper.before_each()
    helper.new_directory("dir")
    helper.new_directory("dir/depth2")
    helper.new_file("dir/file")
  end)

  after_each(helper.after_each)

  it("can show directories recursively", function()
    helper.sync_open("directory/recursive", {opts = {insert = false}})

    assert.exists_pattern("dir/")
    assert.no.exists_pattern("dir/file")
    helper.search("dir/$")

    thetto.execute()

    assert.current_dir("dir")
  end)

  it("can show directories with depth range", function()
    helper.sync_open("directory/recursive", {source_opts = {max_depth = 1}, opts = {insert = false}})

    assert.no.exists_pattern("dir/depth2")
    assert.exists_pattern("dir/$")

    thetto.execute()
  end)

  it("can execute enter", function()
    helper.sync_open("directory/recursive", {opts = {insert = false}})
    helper.search("dir/$")

    thetto.execute("enter")
    thetto.execute("move_to_list")

    assert.exists_pattern("depth2/")
  end)

end)
