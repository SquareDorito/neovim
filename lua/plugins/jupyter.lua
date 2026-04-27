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
      vim.g.molten_virt_lines_off_by_1 = false
      vim.g.molten_output_win_border = { "─", "─", "─", "│", "─", "─", "─", "│" }
      vim.g.molten_output_win_style = "minimal"
      vim.g.molten_output_win_cover_gutter = true
      vim.g.molten_use_border_highlights = true
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

      -- Evaluate the # %%-bounded cell containing the cursor.
      local function eval_cell()
        local cur = vim.api.nvim_win_get_cursor(0)[1]
        local total = vim.api.nvim_buf_line_count(0)
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local function is_marker(s) return s and s:match("^#%s*%%%%") ~= nil end

        local cell_start = 1
        for i = cur, 1, -1 do
          if is_marker(lines[i]) then cell_start = i + 1; break end
        end
        local cell_end = total
        for i = cur + 1, total do
          if is_marker(lines[i]) then cell_end = i - 1; break end
        end
        if cell_start > cell_end then
          vim.notify("Empty cell", vim.log.levels.WARN)
          return
        end
        vim.fn.MoltenEvaluateRange(cell_start, cell_end)
      end
      vim.keymap.set("n", "<leader>mc", eval_cell, { desc = "Molten: eval current # %% cell" })

      -- Jump to the next / previous # %% cell marker.
      local function jump_cell(dir)
        local cur = vim.api.nvim_win_get_cursor(0)[1]
        local total = vim.api.nvim_buf_line_count(0)
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local range = dir > 0 and { cur + 1, total, 1 } or { cur - 1, 1, -1 }
        for i = range[1], range[2], range[3] do
          if lines[i] and lines[i]:match("^#%s*%%%%") then
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            return
          end
        end
      end
      vim.keymap.set("n", "]c", function() jump_cell(1) end,  { desc = "Next # %% cell" })
      vim.keymap.set("n", "[c", function() jump_cell(-1) end, { desc = "Prev # %% cell" })

      -- Insert a new cell below the current line.
      vim.keymap.set("n", "<leader>mn", function()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        vim.api.nvim_buf_set_lines(0, row, row, false, { "", "# %%", "" })
        vim.api.nvim_win_set_cursor(0, { row + 3, 0 })
        vim.cmd("startinsert")
      end, { desc = "Molten: new cell below" })

      -- Render a separator line above each # %% marker and tint the marker row.
      vim.api.nvim_set_hl(0, "JupyterCellMarker", { bold = true, link = "Function" })
      -- Floating output window: tinted background, colored borders for run state.
      vim.api.nvim_set_hl(0, "MoltenOutputWin",         { bg = "#1e2230" })
      vim.api.nvim_set_hl(0, "MoltenOutputWinNC",       { bg = "#1e2230" })
      vim.api.nvim_set_hl(0, "MoltenOutputBorder",      { fg = "#5c6370" })
      vim.api.nvim_set_hl(0, "MoltenOutputBorderSuccess", { fg = "#98c379" })
      vim.api.nvim_set_hl(0, "MoltenOutputBorderFail",  { fg = "#e06c75" })
      local cell_ns = vim.api.nvim_create_namespace("jupyter_cells")
      local function highlight_cells(bufnr)
        if not vim.api.nvim_buf_is_loaded(bufnr) then return end
        vim.api.nvim_buf_clear_namespace(bufnr, cell_ns, 0, -1)
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local has_any = false
        for _, l in ipairs(lines) do
          if l:match("^#%s*%%%%") then has_any = true; break end
        end
        if not has_any then return end
        local width = vim.api.nvim_win_get_width(0)
        local sep = { { string.rep("─", width), "Comment" } }
        for i, line in ipairs(lines) do
          if line:match("^#%s*%%%%") then
            vim.api.nvim_buf_set_extmark(bufnr, cell_ns, i - 1, 0, {
              virt_lines = { sep },
              virt_lines_above = true,
              line_hl_group = "CursorLine",
              hl_group = "JupyterCellMarker",
              end_col = #line,
            })
          end
        end
      end
      vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "InsertLeave", "FileType" }, {
        callback = function(args)
          if vim.bo[args.buf].filetype == "python" then
            highlight_cells(args.buf)
          end
        end,
      })
    end,
    keys = {
      { "<leader>mi", "<cmd>MoltenInit<cr>",                  desc = "Molten: init kernel" },
      { "<leader>ml", "<cmd>MoltenEvaluateLine<cr>",          desc = "Molten: eval line" },
      { "<leader>mr", "<cmd>MoltenReevaluateCell<cr>",        desc = "Molten: re-eval molten cell" },
      { "<leader>mv", ":<C-u>MoltenEvaluateVisual<cr>gv",     mode = "v", desc = "Molten: eval visual" },
      { "<leader>mo", "<cmd>noautocmd MoltenEnterOutput<cr>", desc = "Molten: enter output" },
      { "<leader>mh", "<cmd>MoltenHideOutput<cr>",            desc = "Molten: hide output" },
      { "<leader>md", "<cmd>MoltenDelete<cr>",                desc = "Molten: delete cell" },
    },
  },
}
