local helper = require("thetto/lib/testlib/helper")
local assert = helper.assert
local command = helper.command

describe("file/recursive source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show files recursively", function()
    helper.new_directory("dir")
    helper.new_file("dir/file")

    helper.sync_open("file/recursive", "--no-insert")

    assert.exists_pattern("dir/file")
    helper.search("dir\\/file")

    command("ThettoDo")

    assert.file_name("file")
  end)

  it("can show files in project dir", function()
    require("thetto/target/project").root_patterns = {"0_root_pattern"}

    helper.new_directory("0_root_pattern")
    helper.new_file("0_root_pattern/in_root_pattern")

    helper.sync_open("file/recursive", "--no-insert", "--target=project")

    assert.exists_pattern("root_pattern/in_root_pattern")
  end)

  it("shows error if command does not exist", function()
    require("thetto/source/file/recursive").get_command = function()
      return {"not_exists_cmd"}
    end

    assert.error_message("not_exists_cmd", function()
      command("Thetto file/recursive")
    end)
  end)

end)
