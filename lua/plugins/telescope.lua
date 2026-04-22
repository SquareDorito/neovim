return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },

    config = function()
      local telescope = require("telescope")
      local builtin = require("telescope.builtin")
      local root = require("utils.root") -- ⭐ shared project root

      telescope.setup({
        defaults = {
          cwd = root.get(), -- ensures default sync
        },
      })

      -- 📂 Find files (project root)
      vim.keymap.set("n", "<leader>ff", function()
        builtin.find_files({
          cwd = root.get(),
        })
      end, { desc = "Find files" })

      -- 🔍 Live grep (project root)
      vim.keymap.set("n", "<leader>fg", function()
        builtin.live_grep({
          cwd = root.get(),
        })
      end, { desc = "Live grep" })

      -- 📄 Symbols in current file
      vim.keymap.set("n", "<leader>ss", builtin.lsp_document_symbols, {
        desc = "Document symbols",
      })

      -- 🌍 Symbols across workspace
      vim.keymap.set("n", "<leader>sw", builtin.lsp_workspace_symbols, {
        desc = "Workspace symbols",
      })

      -- 🧠 Buffers (no root needed)
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {
        desc = "Buffers",
      })

      -- 🕘 Recent files
      vim.keymap.set("n", "<leader>fr", builtin.oldfiles, {
        desc = "Recent files",
      })

      -- ⭐ Search everything (file-centric)
      vim.keymap.set("n", "<leader><leader>", function()
        builtin.find_files({
          cwd = root.get(),
        })
      end, {
        desc = "Search files (quick)",
      })
    end,
  },
}
