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

      -- Build an `rg --files` command spanning the project root and extras
      -- (i.e. ~/notebooks), so telescope's find_files sees everything that
      -- *.code-workspace would have shown as a folder.
      local function find_cmd()
        local cmd = { "rg", "--files", "--hidden", "--glob", "!**/.git/**" }
        vim.list_extend(cmd, root.get_all())
        return cmd
      end

      -- 📂 Find files (project root + notebooks)
      vim.keymap.set("n", "<leader>ff", function()
        builtin.find_files({
          find_command = find_cmd(),
        })
      end, { desc = "Find files" })

      -- 🔍 Live grep (project root + notebooks)
      vim.keymap.set("n", "<leader>fg", function()
        builtin.live_grep({
          search_dirs = root.get_all(),
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
          find_command = find_cmd(),
        })
      end, {
        desc = "Search files (quick)",
      })

      -- 🎹 Search all keymaps (very useful)
      vim.keymap.set("n", "<leader>sk", builtin.keymaps, {
        desc = "Search keymaps",
      })

      vim.keymap.set("n", "<leader>sc", builtin.commands, {
        desc = "Search commands",
      })

      -- ⚙️ Search Neovim config files
      vim.keymap.set("n", "<leader>sn", function()
        builtin.find_files({
          cwd = vim.fn.expand("~/.config/nvim"),
        })
      end, {
        desc = "Search Neovim config",
      })

      vim.keymap.set("n", "<leader>sh", builtin.help_tags, {
        desc = "Search help",
      })
    end,
  },
}
