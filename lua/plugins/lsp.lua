return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Derive pyright's extraPaths from this nvim instance's cwd: walk to git
      -- toplevel, append /rebal if present. Each nvim session gets its own
      -- worktree-scoped config; no shared symlinks, no cross-tmux state.
      local function active_rebal()
        local cwd = vim.fn.getcwd()
        local toplevel = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })[1]
        if toplevel and toplevel ~= "" and vim.fn.isdirectory(toplevel .. "/rebal") == 1 then
          return toplevel .. "/rebal"
        end
        return nil
      end

      local conda_prefix = os.getenv("CONDA_PREFIX") or "/opt/data/conda/envs/rebal-prod"
      local extra_paths = {}
      local rebal = active_rebal()
      if rebal then table.insert(extra_paths, rebal) end

      vim.lsp.config("pyright", {
        capabilities = capabilities,
        settings = {
          python = {
            pythonPath = conda_prefix .. "/bin/python",
            analysis = {
              extraPaths = extra_paths,
            },
          },
        },
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
