return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },

    config = function()
      require("neo-tree").setup({
        filesystem = {
          follow_current_file = {
            enabled = true,
          },
          bind_to_cwd = false,
        },
      })

      -- open synced at startup
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          local root = require("utils.root").get()
          vim.cmd("Neotree show " .. root)
        end,
      })

      -- toggle tree
      vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", {
        desc = "Toggle file tree",
      })

      -- focus tree
      vim.keymap.set("n", "<leader>n", "<cmd>Neotree focus<CR>", {
        desc = "Focus file tree",
      })

      -- reveal project root (consistent with system)
      vim.keymap.set("n", "<leader>c", function()
        local root = require("utils.root").get()
        vim.cmd("Neotree show " .. root)
      end, {
        desc = "Reveal project root",
      })

      -- reveal notebooks dir (mirrors the extra folder in *.code-workspace)
      vim.keymap.set("n", "<leader>nb", function()
        vim.cmd("Neotree show " .. vim.fn.expand("~/notebooks"))
      end, {
        desc = "Reveal notebooks",
      })
    end,
  },
}
