return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        vim.notify(
          "nvim-treesitter is not on the master branch yet; run :Lazy sync and restart Neovim",
          vim.log.levels.WARN
        )
        return
      end

      configs.setup({
        ensure_installed = { "python", "lua", "rust", "json", "typescript", "tsx", "javascript", "yaml", "markdown", "markdown_inline" },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })

      -- Neovim 0.12 compatibility shim.
      --
      -- nvim-treesitter's legacy `master` branch does not support Neovim 0.12
      -- (its README says 0.10/0.11 only). On 0.12 the treesitter directive API
      -- changed: the callback's `match[capture_id]` is now a *list* of TSNodes
      -- (`TSNode[]`) instead of a single node. master's `set-lang-from-info-string!`
      -- directive still treats it as a single node, so it hands a Lua table to
      -- get_node_text(), which eventually calls `node:range()` on the table and
      -- crashes any time a markdown fenced-code-block injection is parsed:
      --   treesitter.lua:196 "attempt to call method 'range' (a nil value)"
      -- (seen via treesitter-context -> languagetree:parse on every .md buffer).
      --
      -- Re-register the directive with the correct 0.12 (list) handling. This is
      -- also what makes ```lang fenced code blocks highlight at all. Removing it
      -- once nvim-treesitter is migrated to the `main` branch is safe.
      local tsquery = require("vim.treesitter.query")

      -- Mirrors master's get_parser_from_markdown_info_string alias resolution.
      local info_string_aliases = {
        ex = "elixir",
        pl = "perl",
        sh = "bash",
        uxn = "uxntal",
        ts = "typescript",
      }
      local function lang_from_info_string(alias)
        local matched = vim.filetype.match({ filename = "a." .. alias })
        return matched or info_string_aliases[alias] or alias
      end

      tsquery.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
        local nodes = match[pred[2]]
        -- 0.12 hands us a list of nodes; older versions a single node.
        local node = type(nodes) == "table" and nodes[#nodes] or nodes
        if not node then
          return
        end
        local alias = vim.treesitter.get_node_text(node, bufnr):lower()
        metadata["injection.language"] = lang_from_info_string(alias)
      end, { force = true, all = false })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("treesitter-context").setup({
        enable = true,
        max_lines = 3,
        min_window_height = 0,
        line_numbers = true,
        multiline_threshold = 3,
        mode = "cursor",
        zindex = 20,
        on_attach = function(bufnr)
          if vim.bo[bufnr].buftype ~= "" then
            return false
          end

          local excluded_filetypes = {
            "neo-tree",
            "TelescopePrompt",
            "lazy",
            "mason",
            "snacks_picker",
            "snacks_terminal",
          }

          return not vim.tbl_contains(excluded_filetypes, vim.bo[bufnr].filetype)
        end,
      })

      vim.keymap.set("n", "<leader>tc", "<cmd>TSContext toggle<cr>", {
        desc = "Toggle Treesitter context",
      })
    end,
  },
}
