local filelib = require("thetto.lib.file")

local M = {}

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root(source_ctx.cwd)
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "--no-pager", "status" }
  local states = {
    ["Changes to be committed:"] = "staged",
    ["Changes not staged for commit:"] = "unstaged",
    ["Untracked files:"] = "untracked",
    ["Unmerged paths:"] = "conflict",
  }
  local parse_stage = function(target)
    local path_status, path_part = target:match("([^:]+):%s+(.*)")
    return path_status, path_part
  end
  local parsers = {
    staged = parse_stage,
    unstaged = parse_stage,
    untracked = function(target)
      return "untracked", target
    end,
    conflict = parse_stage,
  }
  local index_status = "staged"
  return require("thetto.util.job").start(cmd, source_ctx, function(output)
    local changed_state = states[output]
    if changed_state then
      index_status = changed_state
      return {
        value = "",
        desc = output,
        kind_name = "git/status/message",
        git_root = git_root,
      }
    end

    local target = output:match("\t(.*)")
    if not target then
      return {
        value = "",
        desc = output,
        kind_name = "git/status/message",
        git_root = git_root,
      }
    end

    local path_status, path_part = parsers[index_status](target)
    local path = vim.split(path_part, " -> ", { plain = true })[1]
    local abs_path = vim.fs.joinpath(git_root, path)

    local kind
    if vim.fn.isdirectory(abs_path) == 1 then
      kind = "git/status/directory"
    end

    local status = ("%-13s"):format(path_status)
    local indent = "    "
    local desc = ("%s%s %s"):format(indent, status, path_part)
    return {
      value = path,
      desc = desc,
      kind_name = kind,
      path = abs_path,
      index_status = index_status,
      column_offsets = {
        value = #indent + #status + 1,
      },
      git_root = git_root,
    }
  end, { cwd = git_root })
end

local hl_groups = {
  staged = "String",
  conflict = "Special",
}
M.highlight = require("thetto.util.highlight").columns({
  {
    group = function(item)
      if not item.index_status then
        return nil
      end
      return hl_groups[item.index_status] or "Boolean"
    end,
    end_key = "value",
  },
})

M.kind_name = "git/status/file"

M.cwd = require("thetto.util.cwd").project()

M.key = require("thetto.util.source_key").cwd()

M.consumer_opts = {
  ui = {
    insert = false,
    display_limit = 10000,
  },
}

return M
