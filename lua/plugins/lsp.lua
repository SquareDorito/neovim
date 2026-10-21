return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Run the active conda env's ty so it resolves that env's packages; ty.toml in the repo supplies extra-paths.
      local conda_prefix = os.getenv("CONDA_PREFIX") or "/opt/data/conda/envs/rebal-prod"
      local ty_bin = conda_prefix .. "/bin/ty"
      vim.lsp.config("ty", {
        capabilities = capabilities,
        cmd = { vim.fn.executable(ty_bin) == 1 and ty_bin or "ty", "server" },
      })
      vim.lsp.enable("ty")

      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
      })
      vim.lsp.enable("ts_ls")

      vim.lsp.config("ruff", {
        capabilities = capabilities,
      })
      vim.lsp.enable("ruff")

      if vim.fn.executable("vscode-eslint-language-server") == 1 then
        vim.lsp.config("eslint", {
          capabilities = capabilities,
        })
        vim.lsp.enable("eslint")
      end

      vim.lsp.config("rust_analyzer", {
        capabilities = capabilities,
      })
      vim.lsp.enable("rust_analyzer")

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

      vim.api.nvim_create_user_command("LspInfo", function()
        vim.cmd("checkhealth vim.lsp")
      end, {})
      vim.api.nvim_create_user_command("LspLog", function()
        vim.cmd("tabnew " .. vim.lsp.get_log_path())
      end, {})
      vim.api.nvim_create_user_command("LspRestart", function()
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
          c:stop()
        end
        vim.defer_fn(function() vim.cmd("edit") end, 100)
      end, {})
    end,
  },
}
