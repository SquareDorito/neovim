return {
  {
    "ishiooon/codex.nvim",
    cond = function() return vim.g.ai_provider == "codex" end,
    dependencies = {
      "folke/snacks.nvim",
    },

    config = function()
      local codex_float_bottom_padding = 4
      local codex_float_top_padding = 1
      local codex_terminal_footer_padding = 2

      local function is_codex_terminal_buffer(bufnr)
        local ok, terminal_buffer = pcall(require, "codex.terminal.buffer")
        return ok and terminal_buffer.is_codex_terminal_buffer(bufnr)
      end

      local function codex_terminal_wins()
        local wins = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_is_valid(win) then
            local bufnr = vim.api.nvim_win_get_buf(win)
            if is_codex_terminal_buffer(bufnr) then
              table.insert(wins, win)
            end
          end
        end
        return wins
      end

      local function resize_codex_terminal_pty(win)
        local bufnr = vim.api.nvim_win_get_buf(win)
        local job_id = vim.b[bufnr].terminal_job_id
        if not job_id then
          return
        end

        local width = vim.api.nvim_win_get_width(win)
        local height = math.max(8, vim.api.nvim_win_get_height(win) - codex_terminal_footer_padding)
        pcall(vim.fn.jobresize, job_id, width, height)
      end

      local function pin_codex_terminal(opts)
        opts = opts or {}
        vim.schedule(function()
          local current_win = vim.api.nvim_get_current_win()
          for _, win in ipairs(codex_terminal_wins()) do
            resize_codex_terminal_pty(win)
            if opts.start_insert and win == current_win then
              vim.api.nvim_win_call(win, function()
                vim.cmd("startinsert")
              end)
            end
          end
        end)
      end

      require("codex").setup({
        terminal_cmd = "codex --dangerously-bypass-approvals-and-sandbox --no-alt-screen",
        auto_start = false,
        keymaps = false,
        terminal = {
          provider = "snacks",
          unfocus_key = false,
          snacks_win_opts = {
            position = "float",
            width = 0.85,
            height = function()
              local available = vim.o.lines
                - vim.o.cmdheight
                - codex_float_top_padding
                - codex_float_bottom_padding
                - 2
              return math.max(8, available)
            end,
            row = codex_float_top_padding,
            border = "rounded",
            on_win = function(win)
              for _, delay in ipairs({ 20, 100, 250 }) do
                vim.defer_fn(function()
                  if win.win and vim.api.nvim_win_is_valid(win.win) then
                    resize_codex_terminal_pty(win.win)
                    pin_codex_terminal({ start_insert = true })
                  end
                end, delay)
              end
            end,
          },
        },
      })

      vim.api.nvim_create_autocmd({
        "TermOpen",
        "TermEnter",
        "BufEnter",
        "WinEnter",
        "WinResized",
        "TextChanged",
        "TextChangedT",
      }, {
        group = vim.api.nvim_create_augroup("CodexTerminalPinBottom", { clear = true }),
        callback = function(args)
          if args.buf and vim.api.nvim_buf_is_valid(args.buf) and not is_codex_terminal_buffer(args.buf) then
            return
          end
          pin_codex_terminal({ start_insert = true })
        end,
      })

      local function focus_codex()
        vim.cmd("CodexFocus")
        pin_codex_terminal({ start_insert = true })
        vim.defer_fn(function()
          pin_codex_terminal({ start_insert = true })
        end, 80)
        vim.defer_fn(function()
          pin_codex_terminal({ start_insert = true })
        end, 250)
      end

      vim.keymap.set("n", "<leader>cc", focus_codex, {
        desc = "Toggle Codex panel",
      })

      vim.keymap.set("n", "<leader>cf", focus_codex, {
        desc = "Codex focus",
      })

      vim.keymap.set({ "n", "t" }, "<leader>cj", focus_codex, {
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
