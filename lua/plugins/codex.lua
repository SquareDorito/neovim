return {
  {
    "ishiooon/codex.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },

    config = function()
      require("codex").setup({
        auto_start = false,
        keymaps = false,
        terminal = {
          provider = "snacks",
          unfocus_key = false,
          snacks_win_opts = {
            position = "float",
            width = 0.85,
            height = 0.85,
            border = "rounded",
          },
        },
      })

      vim.keymap.set("n", "<leader>cc", "<cmd>CodexFocus<cr>", {
        desc = "Toggle Codex panel",
      })

      vim.keymap.set("n", "<leader>cf", "<cmd>CodexFocus<cr>", {
        desc = "Codex focus",
      })

      vim.keymap.set({ "n", "t" }, "<leader>cj", "<cmd>CodexFocus<cr>", {
        desc = "Jump to Codex",
      })

      vim.keymap.set({ "n", "t" }, "<C-]>", function()
        local ok, terminal_buffer = pcall(require, "codex.terminal.buffer")
        if not ok or not terminal_buffer.is_codex_terminal_buffer(vim.api.nvim_get_current_buf()) then
          return
        end

        if vim.api.nvim_get_mode().mode == "t" then
          vim.cmd("stopinsert")
        end

        vim.cmd("CodexFocus")
      end, {
        desc = "Hide active Codex window",
      })

      vim.keymap.set("v", "<leader>cs", "<cmd>CodexSend<cr>", {
        desc = "Send selection to Codex",
      })

      vim.keymap.set("n", "<leader>ca", "<cmd>CodexTreeAdd<cr>", {
        desc = "Add file to Codex context",
      })

      vim.keymap.set("n", "<leader>cb", "<cmd>CodexBufferAdd<cr>", {
        desc = "Add current buffer to Codex context",
      })
    end,
  },
}
