return {
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          python = { "ruff_format" }, -- fast + modern default
        },

        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })

      -- manual format key (optional but useful)
      vim.keymap.set("n", "<leader>f", function()
        require("conform").format({ async = true })
      end, {
        desc = "Format buffer",
      })
    end,
  },
}
