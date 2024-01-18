local helper = require("thetto.test.helper")

describe("require handler", function()
  before_each(helper.before_each)
  after_each(helper.after_each)

  local pattern = helper.root .. "/lua/thetto/handler/**/*.lua"
  local paths = vim.fn.glob(pattern, false, true)
  for _, path in ipairs(paths) do
    local module_name = vim.split(path, "thetto.nvim/lua/", { plain = true })[2]:gsub(".lua$", ""):gsub("/", "%.")
    it(module_name, function()
      require(module_name)
    end)
  end
end)
