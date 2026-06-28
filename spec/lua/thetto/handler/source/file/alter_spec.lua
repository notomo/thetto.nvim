local ntf = require("ntf")
local describe, it, before_each, after_each = ntf.describe, ntf.it, ntf.before_each, ntf.after_each
local helper = require("thetto.test.helper")
local assert = helper.typed_assert(ntf.assert)

local alter = require("thetto.handler.source.file.alter")

describe("file/alter source", function()
  before_each(function()
    helper.before_each()
    helper.test_data = require("thetto.vendor.misclib.test.data_dir").setup(vim.fs.joinpath(helper.root, "spec"))
  end)

  after_each(function()
    helper.test_data:teardown()
    helper.after_each()
  end)

  local function alter_paths(file_path, pattern_groups)
    local bufnr = vim.fn.bufadd(file_path)
    vim.fn.bufload(bufnr)
    local items = alter.collect({
      bufnr = bufnr,
      opts = { pattern_groups = pattern_groups, allow_new = false },
    })
    return vim.tbl_map(function(item)
      return item.path
    end, items)
  end

  it("finds the test file for an implementation file in the same directory", function()
    local impl = helper.test_data:create_file("proj/foo.py")
    local test = helper.test_data:create_file("proj/test_foo.py")

    local paths = alter_paths(impl, { { "test_%.py", "%.py" } })

    assert.same({ test }, paths)
  end)

  it("finds the implementation file for a test file in the same directory", function()
    local impl = helper.test_data:create_file("proj/foo.py")
    helper.test_data:create_file("proj/test_foo.py")

    local paths = alter_paths(helper.test_data:path("proj/test_foo.py"), { { "test_%.py", "%.py" } })

    assert.same({ impl }, paths)
  end)

  it("keeps the directory for a suffix pattern", function()
    local impl = helper.test_data:create_file("proj/foo.go")
    local test = helper.test_data:create_file("proj/foo_test.go")

    local paths = alter_paths(impl, { { "%_test.go", "%.go" } })

    assert.same({ test }, paths)
  end)

  it("finds an alternative across directories", function()
    local impl = helper.test_data:create_file("vim/lua/hoge/x/a.lua")
    local spec = helper.test_data:create_file("vim/spec/lua/hoge/x/a_spec.lua")

    local pattern_groups = { { "%/spec/lua/%_spec.lua", "%/lua/%.lua" } }

    assert.same({ spec }, alter_paths(impl, pattern_groups))
    assert.same({ impl }, alter_paths(spec, pattern_groups))
  end)
end)
