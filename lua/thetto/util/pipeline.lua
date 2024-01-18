local M = {}

function M.default()
  return M.merge({
    M.list({
      require("thetto.util.filter").by_name("substring"),
      require("thetto.util.filter").by_name("substring", {
        opts = { inversed = true },
      }),
    }),
    M.apply_source(),
  })
end

function M.list(stages)
  return function(_, _)
    return stages
  end
end

function M.merge(modifiers)
  return function(current_stages, opts)
    local new_stages = current_stages
    for _, modifier in ipairs(modifiers) do
      new_stages = modifier(new_stages, opts)
    end
    return new_stages
  end
end

function M.apply_source()
  return function(current_stages, opts)
    local modify = opts.source.modify_pipeline or function(stages, _)
      return stages
    end
    return modify(current_stages, opts)
  end
end

function M.prepend(stages)
  return function(current_stages, _)
    local new_stages = {}
    vim.list_extend(new_stages, stages)
    vim.list_extend(new_stages, current_stages)
    return new_stages
  end
end

function M.append(stages)
  return function(current_stages, _)
    local new_stages = {}
    vim.list_extend(new_stages, current_stages)
    vim.list_extend(new_stages, stages)
    return new_stages
  end
end

return M
