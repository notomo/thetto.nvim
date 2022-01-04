local M = {}

function M.collect()
  return {}
end

function M.highlight(_, _, _, _) end

function M.highlight_sign(self, bufnr, first_line, items)
  if #self.compiled_colors == 0 then
    return
  end

  local highlighter = self.highlights:create(bufnr)
  for i, item in ipairs(items) do
    for _, color in ipairs(self.compiled_colors) do
      if color.always or color.regex:match_str(item[self.color_label_key]) then
        highlighter:set_virtual_text(first_line + i - 1, color.chunks, {
          virt_text_pos = "right_align",
          ephemeral = true,
        })
        break
      end
    end
  end
end

M.color_label_key = "value"
M.colors = { { always = true, pattern = "", chunks = { { " ", "ThettoColorLabelOthers" } } } }
M.filters = { "substring" }
M.sorters = {}
M.kind_name = "base"
M.opts = {}
M.chunk_max_count = 10000

return M
