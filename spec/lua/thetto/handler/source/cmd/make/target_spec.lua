local ntf = require("ntf")
local describe, it, before_each, after_each = ntf.describe, ntf.it, ntf.before_each, ntf.after_each
local helper = require("thetto.test.helper")
local assert = helper.typed_assert(ntf.assert)

local target = require("thetto.handler.source.cmd.make.target")

describe("cmd/make/target source", function()
  before_each(function()
    helper.before_each()
    helper.test_data = require("thetto.vendor.misclib.test.data_dir").setup(vim.fs.joinpath(helper.root, "spec"))
  end)

  after_each(function()
    helper.test_data:teardown()
    helper.after_each()
  end)

  local function targets(makefile_path)
    local items = target._load(makefile_path, vim.fs.dirname(makefile_path))
    return vim.tbl_map(function(item)
      return item.value
    end, items)
  end

  it("collects the item that runs make with no target once", function()
    helper.test_data:create_file("Makefile", "own_target:\n\techo own\n")
    helper.test_data:create_file("other.mk", "mk_target:\n\techo mk\n")

    local items = target.collect({ cwd = helper.test_data.full_path })
    local values = vim.tbl_map(function(item)
      return item.value
    end, items)

    assert.same({ "", "own_target", "mk_target" }, values)
  end)

  it("collects the targets of an included file", function()
    helper.test_data:create_file("shared/shared.mk", "shared_target:\n\techo shared\n")
    local path = helper.test_data:create_file("Makefile", "include shared/shared.mk\n\nown_target:\n\techo own\n")

    assert.same({ "shared_target", "own_target" }, targets(path))
  end)

  it("collects the targets of a file included by a variable path", function()
    helper.test_data:create_file("shared/shared.mk", "shared_target:\n\techo shared\n")
    local path = helper.test_data:create_file("Makefile", "SHARED_DIR ?= shared\ninclude $(SHARED_DIR)/shared.mk\n")

    assert.same({ "shared_target" }, targets(path))
  end)

  it("collects the targets of a file included by an environment variable path", function()
    helper.test_data:create_file("shared/shared.mk", "shared_target:\n\techo shared\n")
    local path = helper.test_data:create_file("Makefile", "include ${THETTO_TEST_SHARED_DIR}/shared.mk\n")

    vim.env.THETTO_TEST_SHARED_DIR = helper.test_data:path("shared")
    local values = targets(path)
    vim.env.THETTO_TEST_SHARED_DIR = nil

    assert.same({ "shared_target" }, values)
  end)

  it("prefers the environment over the default of an optional assignment", function()
    helper.test_data:create_file("shared/shared.mk", "shared_target:\n\techo shared\n")
    helper.test_data:create_file("default/shared.mk", "default_target:\n\techo default\n")
    local path = helper.test_data:create_file("Makefile", "SHARED_DIR ?= default\ninclude $(SHARED_DIR)/shared.mk\n")

    vim.env.SHARED_DIR = helper.test_data:path("shared")
    local values = targets(path)
    vim.env.SHARED_DIR = nil

    assert.same({ "shared_target" }, values)
  end)
end)
