return {
  {
    "ishiooon/codex.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },

    config = function()
      require("codex").setup({
        terminal = {
          split = "horizontal",
        },
      })

      -- Toggle Codex panel
      vim.keymap.set("n", "<leader>cc", function()
        vim.cmd("Codex")

        vim.defer_fn(function()
          vim.cmd("startinsert")
        end, 50)
      end, {
        desc = "Toggle Codex panel",
      })

      -- Focus Codex panel if already open
      vim.keymap.set("n", "<leader>cf", "<cmd>CodexFocus<cr>", {
        desc = "Codex focus",
      })

      -- Send selection to Codex
      vim.keymap.set("v", "<leader>cs", "<cmd>CodexSend<cr>", {
        desc = "Send selection to Codex",
      })

      -- Send file from Neo-tree
      vim.keymap.set("n", "<leader>ct", "<cmd>CodexTreeAdd<cr>", {
        desc = "Add file to Codex context",
      })

      vim.keymap.set("n", "<leader>cb", "<cmd>CodexBufferAdd<cr>", {
        desc = "Add current buffer to Codex context",
      })
    end,
  },
}
