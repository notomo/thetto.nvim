local filelib = require("thetto.lib.file")

local M = {}

M.opts = {
  commit_hash = nil,
  path = nil,
}

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root(source_ctx.cwd)
  if err then
    return err
  end

  local commits = {}
  local state_commit_hash
  local parsers, next_parser
  parsers = {
    commit_hash = function(line)
      local splitted = vim.split(line, " ", { plain = true })
      state_commit_hash = splitted[1]
      if not commits[state_commit_hash] then
        commits[state_commit_hash] = {}
      end
      next_parser = parsers.others
    end,
    others = function(line)
      local index = line:find(" ")
      if not index then
        return
      end
      local key = line:sub(1, index - 1)
      local value = line:sub(index + 1)
      commits[state_commit_hash][key] = value
    end,
  }
  next_parser = parsers.commit_hash

  local path = source_ctx.opts.path or vim.api.nvim_buf_get_name(source_ctx.bufnr)
  local cmd = { "git", "--no-pager", "blame", "--porcelain" }
  if source_ctx.opts.commit_hash then
    table.insert(cmd, source_ctx.opts.commit_hash)
  end
  vim.list_extend(cmd, { "--", path })

  local row = 0
  return require("thetto.util.job")
    .promise({ "git", "rev-parse", "--short", "HEAD" }, {
      cwd = git_root,
      on_exit = function() end,
    })
    :next(function(short_commit_hash)
      local digit = #short_commit_hash
      return require("thetto.util.job").start(cmd, source_ctx, function(output)
        if not vim.startswith(output, "\t") then
          next_parser(output)
          return nil
        end

        next_parser = parsers.commit_hash
        row = row + 1

        local message = commits[state_commit_hash].summary
        local user_name = commits[state_commit_hash].author
        local date = vim.fn.strftime("%Y-%m-%d", commits[state_commit_hash]["author-time"])
        local commit_hash = state_commit_hash:sub(1, digit)
        local commit_hash_is_temporary = commit_hash == ("0"):rep(digit)
        local value = ("%s %s %s <%s>"):format(commit_hash, date, message, user_name)
        return {
          value = value,
          path = path,
          row = row,
          commit_hash = not commit_hash_is_temporary and state_commit_hash or nil,
          column_offsets = {
            date = #commit_hash + 1,
            message = #commit_hash + 1 + #date + 1,
            user_name = #message + 1 + #date + 1 + #commit_hash + 1,
          },
        }
      end, {
        cwd = git_root,
        consume = function(observer, to_items, outputs)
          vim.schedule(function()
            observer:next(to_items(outputs))
          end)
        end,
        complete = function(observer)
          vim.schedule(function()
            observer:complete()
          end)
        end,
      })
    end)
end

M.highlight = require("thetto.util.highlight").columns({
  {
    group = "Comment",
    end_key = "date",
  },
  {
    group = "Conditional",
    start_key = "date",
    end_key = "message",
  },
  {
    group = "Label",
    start_key = "user_name",
  },
})

M.kind_name = "file" -- to show file preview

M.cwd = require("thetto.util.cwd").project()

return M
