return {
  {
    "folke/snacks.nvim",
    cond = function() return vim.g.ai_provider == "claude" end,
    keys = {
      {
        "<leader>cc",
        function()
          if _G.close_bottom_term_if_open and _G.close_bottom_term_if_open() then
            return
          end
          Snacks.terminal.toggle({ "claude", "--dangerously-skip-permissions" }, {
            win = {
              position = "float",
              width = 0.85,
              height = 0.85,
              border = "rounded",
            },
          })
        end,
        mode = { "n", "t" },
        desc = "Close bottom term / toggle Claude panel",
      },
    },
  },
}
