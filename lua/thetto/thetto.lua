local M = {}

local prompt_name = "> "

M.start = function(source, opts)
  local lines = {}
  local candidates = source.make()
  local partial = vim.tbl_values({unpack(candidates, 0, opts.height - 1)})
  for _, candidate in pairs(partial) do
    table.insert(lines, candidate.value)
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  local window_id =
    vim.api.nvim_open_win(
    bufnr,
    true,
    {
      width = opts.width,
      height = opts.height,
      relative = "editor",
      row = opts.row,
      col = opts.column,
      external = false,
      style = "minimal"
    }
  )
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "buftype", "prompt")
  vim.api.nvim_win_set_option(window_id, "scrolloff", 0)
  vim.api.nvim_win_set_option(window_id, "sidescrolloff", 0)
  vim.b._thetto_state = {all = candidates, partial = partial}

  vim.api.nvim_command("startinsert")
  vim.schedule(M.on_changed)

  local on_changed =
    ("autocmd TextChanged,TextChangedI <buffer=%s> lua require 'thetto/thetto'.on_changed(%s, %s)"):format(
    bufnr,
    bufnr,
    window_id
  )
  vim.api.nvim_command(on_changed)

  vim.fn.prompt_setprompt(bufnr, prompt_name)

  local rhs =
    ("<Cmd>lua require 'thetto/thetto'.finish(%s, %s, '%s', '%s')<CR>"):format(
    bufnr,
    window_id,
    source.kind_name,
    opts.action_name
  )
  vim.api.nvim_buf_set_keymap(bufnr, "i", "<CR>", rhs, {noremap = true})
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", rhs, {noremap = true})
end

M.on_changed = function(bufnr, window_id)
  vim.api.nvim_buf_set_option(bufnr, "modified", false)

  local state = vim.b._thetto_state
  if state == nil then
    return
  end

  local prompt = vim.fn.getline("$")
  local texts = vim.split(prompt:sub(#prompt_name + 1), "%s")
  local lines = {}
  local height = vim.api.nvim_win_get_height(window_id)
  local partial = {}
  for _, candidate in pairs(state.all) do
    local ok = true
    for _, text in ipairs(texts) do
      if not (candidate.value):find(text) then
        ok = false
        break
      end
    end

    if ok then
      table.insert(partial, candidate)
    end
  end
  vim.api.nvim_buf_set_var(bufnr, "_thetto_state", {all = state.all, partial = partial})
  print(#partial)
  for _, c in pairs({unpack(partial, 0, height - 1)}) do
    table.insert(lines, c.value)
  end

  if #lines < height - 1 then
    lines = vim.list_extend(lines, vim.fn["repeat"]({""}, height - 1 - #lines))
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -(#prompt_name), false, lines)
  vim.api.nvim_buf_set_option(bufnr, "modified", false)
end

local close = function(window_id)
  if window_id == "" then
    return
  end
  if not vim.api.nvim_win_is_valid(window_id) then
    return
  end
  vim.api.nvim_win_close(window_id, true)
end

find_kind = function(kind_name)
  local name = ("thetto/kind/%s"):format(kind_name)
  local ok, module = pcall(require, name)
  if not ok then
    return nil
  end
  return module
end

M.finish = function(_, window_id, kind_name, action_name)
  local candidates = vim.b._thetto_state.partial
  local index = vim.fn.line(".")
  local height = vim.api.nvim_win_get_height(window_id)
  if index >= height then
    index = 1
  end

  close(window_id)
  vim.api.nvim_command("stopinsert")

  local kind = find_kind(kind_name)
  if kind == nil then
    return vim.api.nvim_err_write("not found kind: " .. kind_name .. "\n")
  end

  local candidate = candidates[index]
  local action = kind[action_name]
  if action == nil then
    return vim.api.nvim_err_write("not found action: " .. action_name .. "\n")
  end
  action({candidate})
end

return M
