return {
  -- Edit .ipynb transparently as plain text via the jupytext CLI
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    opts = {
      style = "hydrogen",
      output_extension = "py",
      force_ft = "python",
    },
  },

  -- Run code cells against a live Jupyter kernel
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    lazy = false,
    init = function()
      vim.g.molten_image_provider = "none"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_virt_text_output = true
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_lines_off_by_1 = true
    end,
    config = function()
      -- Auto-init a kernel when opening a .ipynb. Uses the currently activated
      -- conda env's kernel (via $CONDA_DEFAULT_ENV); falls back to python3.
      local group = vim.api.nvim_create_augroup("MoltenAutoInit", { clear = true })
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        group = group,
        pattern = "*.ipynb",
        callback = function(args)
          if vim.b[args.buf].molten_initialized then return end
          vim.b[args.buf].molten_initialized = true
          vim.defer_fn(function()
            local conda_env = os.getenv("CONDA_DEFAULT_ENV")
            local kernel = (conda_env and conda_env ~= "base") and conda_env or "python3"
            pcall(vim.cmd, "MoltenInit " .. kernel)
          end, 200)
        end,
      })
    end,
    keys = {
      { "<leader>mi", "<cmd>MoltenInit<cr>",                  desc = "Molten: init kernel" },
      { "<leader>ml", "<cmd>MoltenEvaluateLine<cr>",          desc = "Molten: eval line" },
      { "<leader>mc", "<cmd>MoltenReevaluateCell<cr>",        desc = "Molten: re-eval cell" },
      { "<leader>mv", ":<C-u>MoltenEvaluateVisual<cr>gv",     mode = "v", desc = "Molten: eval visual" },
      { "<leader>mo", "<cmd>noautocmd MoltenEnterOutput<cr>", desc = "Molten: enter output" },
      { "<leader>mh", "<cmd>MoltenHideOutput<cr>",            desc = "Molten: hide output" },
      { "<leader>md", "<cmd>MoltenDelete<cr>",                desc = "Molten: delete cell" },
    },
  },
}
