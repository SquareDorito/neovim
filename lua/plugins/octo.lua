-- GitHub issues/PRs inside Neovim, backed by the `gh` CLI.
-- Review PRs, comment, and open new PRs without leaving the editor.
--
-- Requires `gh` on PATH and an authenticated token (`gh auth status`).
-- Issue/PR/user completion inside octo buffers is octo's omnifunc: <C-x><C-o>.
-- Note: this repo family also uses Azure DevOps remotes (see gitlinker.lua);
-- octo only ever touches GitHub remotes.
return {
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>op", "<cmd>Octo pr list<cr>",      desc = "Octo: list PRs" },
      { "<leader>oP", "<cmd>Octo pr create<cr>",    desc = "Octo: create PR" },
      { "<leader>oo", "<cmd>Octo pr search<cr>",    desc = "Octo: search PRs" },
      { "<leader>oi", "<cmd>Octo issue list<cr>",   desc = "Octo: list issues" },
      { "<leader>oI", "<cmd>Octo issue create<cr>", desc = "Octo: create issue" },
      { "<leader>or", "<cmd>Octo review start<cr>", desc = "Octo: start review" },
      -- Octo's own submit/discard maps (<localleader>vs / vd) are buffer-local to
      -- the review diff + file panel; these work from anywhere in the review tab.
      { "<leader>ov", "<cmd>Octo review submit<cr>",  desc = "Octo: submit review" },
      { "<leader>oV", "<cmd>Octo review discard<cr>", desc = "Octo: discard review" },
      { "<leader>oa", "<cmd>Octo actions<cr>",      desc = "Octo: all actions" },
    },
    opts = {
      picker = "telescope",
      enable_builtin = true,
      default_merge_method = "squash",
      suppress_missing_scope = {
        -- The container token lacks `project`; don't nag on every open.
        projects_v2 = true,
      },
      mappings_disable_default = false,
    },
    config = function(_, opts)
      require("octo").setup(opts)

      -- Octo buffers are markdown-ish; keep the treesitter/markdown niceties
      -- but drop indent guides, which fight the timeline rendering.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "octo",
        callback = function(args)
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
          vim.opt_local.spell = true
          pcall(function()
            require("ibl").setup_buffer(args.buf, { enabled = false })
          end)
        end,
      })
    end,
  },
}
