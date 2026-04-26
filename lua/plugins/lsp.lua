return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.lsp.config("pyright", {
        capabilities = capabilities,
      })
      vim.lsp.enable("pyright")

      vim.lsp.config("tsserver", {
        capabilities = capabilities,
      })
      vim.lsp.enable("tsserver")

      vim.lsp.config("ruff", {
        capabilities = capabilities,
      })
      vim.lsp.enable("ruff")

      vim.lsp.config("eslint", {
        capabilities = capabilities,
      })
      vim.lsp.enable("eslint")

      vim.keymap.set("n", "gd", vim.lsp.buf.definition, {
        desc = "Go to definition",
      })
      vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, {
        desc = "Show references",
      })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, {
        desc = "Hover documentation",
      })
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {
        desc = "Rename symbol",
      })
      vim.keymap.set("n", "gi", function()
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
          if c.server_capabilities.implementationProvider then
            vim.lsp.buf.implementation()
            return
          end
        end
        vim.lsp.buf.definition()
      end, {
        desc = "Go to implementation (falls back to definition)",
      })
      vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, {
        desc = "Go to type definition",
      })

      vim.keymap.set("n", "<A-CR>", vim.lsp.buf.code_action, {
        desc = "Code action (quick fix)",
      })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {
        desc = "Code actions",
      })
      vim.keymap.set("n", "<leader>af", function()
        vim.lsp.buf.code_action({
          apply = true,
          context = {
            only = { "source.fixAll", "source.organizeImports" },
          },
        })
      end, {
        desc = "Fix all and organize imports",
      })
    end,
  },
}
