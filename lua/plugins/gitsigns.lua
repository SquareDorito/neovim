return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local gs = require("gitsigns")

      gs.setup({
        signs = {
          add          = { text = "│" },
          change       = { text = "│" },
          delete       = { text = "_" },
          topdelete    = { text = "‾" },
          changedelete = { text = "~" },
          untracked    = { text = "┆" },
        },
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol",
          delay = 500,
          ignore_whitespace = false,
        },
        current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> • <summary>",
      })

      vim.keymap.set("n", "<leader>gb", function()
        gs.blame_line({ full = true })
      end, { desc = "Git blame line (popup)" })

      vim.keymap.set("n", "<leader>gB", function()
        gs.blame()
      end, { desc = "Git blame file (pane)" })

      vim.keymap.set("n", "<leader>gt", gs.toggle_current_line_blame, {
        desc = "Toggle inline git blame",
      })

      vim.keymap.set("n", "<leader>gp", gs.preview_hunk, {
        desc = "Preview hunk",
      })

      vim.keymap.set("n", "]c", function()
        if vim.wo.diff then return "]c" end
        vim.schedule(gs.next_hunk)
        return "<Ignore>"
      end, { expr = true, desc = "Next hunk" })

      vim.keymap.set("n", "[c", function()
        if vim.wo.diff then return "[c" end
        vim.schedule(gs.prev_hunk)
        return "<Ignore>"
      end, { expr = true, desc = "Prev hunk" })
    end,
  },
}
