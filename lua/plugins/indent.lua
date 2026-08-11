return {
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
        highlight = "IblIndent",
      },
      scope = {
        enabled = true,
        char = "│",
        show_start = true,
        show_end = false,
        highlight = "IblScope",
      },
      exclude = {
        filetypes = {
          "",
          "TelescopePrompt",
          "TelescopeResults",
          "checkhealth",
          "help",
          "lazy",
          "man",
          "mason",
          "neo-tree",
          "snacks_picker",
          "snacks_terminal",
        },
        buftypes = {
          "terminal",
          "nofile",
          "quickfix",
          "prompt",
        },
      },
    },
    config = function(_, opts)
      local hooks = require("ibl.hooks")

      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, "IblIndent", { fg = "#303540" })
        vim.api.nvim_set_hl(0, "IblScope", { fg = "#7f848e", bold = true })
      end)

      require("ibl").setup(opts)
    end,
  },
}
