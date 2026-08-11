return {
  {
    "folke/snacks.nvim",
    lazy = false,
    config = function()
      require("ai").setup()
    end,
  },
}
