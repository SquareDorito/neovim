-- Browser-based markdown preview with mermaid/plantuml diagram support.
--
-- NOTE: this container has no network, so lazy.nvim cannot clone the plugin,
-- and the plugin's build step needs npm to fetch its preview app. Do both
-- from a machine with network access:
--   git clone https://github.com/iamcco/markdown-preview.nvim \
--     ~/.local/share/nvim/lazy/markdown-preview.nvim
--   cd ~/.local/share/nvim/lazy/markdown-preview.nvim/app && npx --yes yarn install
-- Until the files are present, lazy will simply report it as missing and the
-- rest of the config keeps working.
local vendored = vim.loop.fs_stat(vim.fn.stdpath("data") .. "/lazy/markdown-preview.nvim") ~= nil

return {
  {
    "iamcco/markdown-preview.nvim",
    enabled = vendored,
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown", "markdown.mdx" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_auto_close = false

      -- SSH'd into the host with no local browser to launch: yank the
      -- preview URL to the clipboard instead of shelling out to xdg-open.
      -- mkdp_browserfunc must name a plain Vimscript function (it's called
      -- via Vim's `function()`, which can't resolve `v:lua.foo` directly),
      -- so define a thin VimL wrapper that calls into Lua.
      _G.mkdp_yank_url = function(url)
        vim.fn.setreg("+", url)
        vim.notify("Markdown preview URL yanked: " .. url)
      end
      vim.cmd([[
        function! MkdpYankUrl(url)
          call v:lua.mkdp_yank_url(a:url)
        endfunction
      ]])
      vim.g.mkdp_browserfunc = "MkdpYankUrl"
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Toggle markdown preview" },
    },
  },
}
