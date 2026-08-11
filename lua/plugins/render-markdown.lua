-- In-editor markdown rendering: styled headings, concealed syntax, checkboxes,
-- rendered tables, code-block backgrounds, etc.
--
-- NOTE: this container has no network, so lazy.nvim cannot clone the plugin.
-- Vendor it once from a machine with download access (see README/commit notes):
--   git clone https://github.com/MeanderingProgrammer/render-markdown.nvim \
--     ~/.local/share/nvim/lazy/render-markdown.nvim
-- Until the files are present, lazy will simply report it as missing and the
-- rest of the config keeps working.
-- Only register the plugin once it has actually been vendored. Without this
-- guard lazy.nvim tries to `git clone` it on every startup, which hangs forever
-- in this offline container and slows the editor down.
local vendored = vim.loop.fs_stat(vim.fn.stdpath("data") .. "/lazy/render-markdown.nvim") ~= nil

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = vendored,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "markdown", "markdown.mdx" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      -- Render while editing too, not only in normal mode, but reveal the raw
      -- source on the line the cursor is on so editing stays predictable.
      render_modes = { "n", "c", "t" },
      anti_conceal = { enabled = true },
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
      heading = {
        sign = false,
      },
    },
  },
}
