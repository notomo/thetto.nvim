local setup_highlight_groups = function()
  local highlightlib = require("thetto.vendor.misclib.highlight")
  return {
    ThettoUiSidecarTitle = highlightlib.define("ThettoUiSidecarTitle", {
      fg = vim.api.nvim_get_hl(0, { name = "Comment" }).fg,
      bg = vim.api.nvim_get_hl(0, { name = "NormalFloat" }).bg,
    }),
    ThettoUiItemListTitle = highlightlib.define("ThettoUiSidecarTitle", {
      fg = vim.api.nvim_get_hl(0, { name = "Comment" }).fg,
      bg = vim.api.nvim_get_hl(0, { name = "NormalFloat" }).bg,
    }),
    ThettoUiItemListFooter = highlightlib.link("ThettoUiItemListFooter", "StatusLine"),
    ThettoUiAboveBorder = highlightlib.define("ThettoUiAboveBorder", {
      fg = vim.api.nvim_get_hl(0, { name = "Comment" }).fg,
      bg = vim.api.nvim_get_hl(0, { name = "NormalFloat" }).bg,
    }),
    ThettoUiBorder = highlightlib.link("ThettoUiBorder", "NormalFloat"),
    ThettoUiPreview = highlightlib.link("ThettoUiPreview", "Search"),
  }
end

local group = vim.api.nvim_create_augroup("thetto_highlight_group", {})
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
  group = group,
  pattern = { "*" },
  callback = setup_highlight_groups,
})

return setup_highlight_groups()
