local filelib = require("thetto2.lib.file")

local M = {}

function M.collect(source_ctx)
  local git_root, err = filelib.find_git_root(source_ctx.cwd)
  if err ~= nil then
    return nil, err
  end

  local cmd = { "git", "--no-pager", "stash", "list", "--pretty=format:%gD %s" }
  return require("thetto2.util.job").start(cmd, source_ctx, function(output)
    local stash_name = output:match("^(%S+)")
    return {
      value = output,
      stash_name = stash_name,
      git_root = git_root,
      column_offsets = {
        stash_name = 0,
        description = #stash_name + 1,
      },
    }
  end, { cwd = git_root })
end

M.highlight = require("thetto2.util.highlight").columns({
  {
    group = "Comment",
    start_key = "description",
  },
})

M.kind_name = "word"

M.behaviors = {
  insert = false,
  cwd = require("thetto2.util.cwd").project(),
}

M.actions = {

  action_tab_open = function(items)
    return require("thetto2.handler.kind.git._util").open_diff(items, function(bufnr)
      require("thetto2.lib.buffer").open_scratch_tab()
      vim.cmd.buffer(bufnr)
    end)
  end,

  get_preview = function(items, _, ctx)
    local item = items[1]
    if not item then
      return nil
    end

    local bufnr = require("thetto2.util.git").diff_buffer()
    local promise = require("thetto2.handler.kind.git._util").render_diff(bufnr, item)
    local err = ctx.ui:open_preview(item, { raw_bufnr = bufnr })
    if err then
      return nil, err
    end
    return promise
  end,

  action_create = function(items)
    local item = items[1]
    if not item then
      return
    end

    return require("thetto2.util.input")
      .promise({
        prompt = "Create stash: ",
      })
      :next(function(input)
        if not input or input == "" then
          return require("thetto2.vendor.misclib.message").info("invalid input to create stash")
        end
        return require("thetto2.util.job")
          .promise({ "git", "stash", "save", input }, { cwd = item.git_root })
          :next(function()
            return require("thetto2.vendor.misclib.message").info(("Created stash: %s"):format(input))
          end)
      end)
  end,

  action_pop = function(items)
    local item = items[1]
    if not item then
      return
    end
    return require("thetto2.util.job")
      .promise({ "git", "stash", "pop", item.stash_name }, {
        on_exit = function() end,
        cwd = item.git_root,
      })
      :next(function()
        return require("thetto2.vendor.misclib.message").info(("Pop stash: %s"):format(item.stash_name))
      end)
  end,

  action_apply = function(items)
    local item = items[1]
    if not item then
      return
    end
    return require("thetto2.util.job")
      .promise({ "git", "stash", "apply", item.stash_name }, {
        on_exit = function() end,
        cwd = item.git_root,
      })
      :next(function()
        return require("thetto2.vendor.misclib.message").info(("Applied stash: %s"):format(item.stash_name))
      end)
  end,

  action_delete = function(items)
    local item = items[1]
    if not item then
      return
    end
    return require("thetto2.util.job")
      .promise({ "git", "stash", "drop", item.stash_name }, {
        on_exit = function() end,
        cwd = item.git_root,
      })
      :next(function()
        return require("thetto2.vendor.misclib.message").info(("Drop stash: %s"):format(item.stash_name))
      end)
  end,
}

return M
