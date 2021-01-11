local helper = require("thetto/lib/testlib/helper")
local command = helper.command

describe("file/in_dir source", function()

  before_each(helper.before_each)
  after_each(helper.after_each)

  it("can show current dir files", function()
    helper.new_file("oldfile", [[for mru test]])
    helper.new_directory("dir")
    helper.new_file("dir/file")

    command("Thetto file/in_dir --no-insert")

    assert.exists_pattern("oldfile")
    helper.search("dir")

    command("ThettoDo")

    assert.current_dir("dir")

    command("Thetto file/in_dir --no-insert")
    helper.search("file")

    command("ThettoDo")

    assert.file_name("file")
  end)

  it("can show files in project dir", function()
    require("thetto/target/project").root_patterns = {"0_root_pattern"}

    helper.new_directory("0_root_pattern")
    helper.new_directory("dir")
    helper.cd("dir")

    command("Thetto file/in_dir --no-insert --target=project")

    command("normal! gg")
    assert.current_line("0_root_pattern/")
  end)

end)
