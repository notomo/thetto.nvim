local helper = require("thetto/lib/testlib/helper")
local thetto = helper.require("thetto")

describe("lua/loaded source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show loaded packages", function()
    package.loaded["thetto/lua_loaded_test"] = helper
    thetto.start("lua/loaded")
    helper.sync_input({"lua_loaded_test"})

    thetto.execute("move_to_list")
    assert.exists_pattern("thetto/lua_loaded_test")
  end)

  it("can unload a package", function()
    package.loaded["thetto/lua_unload_test"] = helper
    thetto.start("lua/loaded")
    helper.sync_input({"lua_unload_test"})

    thetto.execute("move_to_list")
    helper.search("thetto/lua_unload_test")

    thetto.execute("unload")

    thetto.start("lua/loaded")
    thetto.execute("move_to_list")
    assert.no.exists_pattern("thetto/lua_unload_test")
  end)

end)
