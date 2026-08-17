-- Whole-diff viewer: file tree + side-by-side, over arbitrary git revisions.
-- Complements gitsigns (hunk-level, in-buffer) and replaces the octo review
-- diff in this container, where `gh` cannot reach GitHub.
return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff working tree" },
      { "<leader>gD", "<cmd>DiffviewOpen origin/master...HEAD<cr>", desc = "Diff branch vs master" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Branch history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = { merge_tool = { layout = "diff3_mixed" } },
    },
  },
}
