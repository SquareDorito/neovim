return {
  {
    "b0o/incline.nvim",
    event = "BufReadPre",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local devicons = require("nvim-web-devicons")
      local root = require("utils.root")

      require("incline").setup({
        window = {
          margin = { vertical = 0, horizontal = 1 },
          padding = 1,
        },
        hide = {
          cursorline = false,
          focused_win = false,
          only_win = false,
        },
        render = function(props)
          local bufname = vim.api.nvim_buf_get_name(props.buf)
          if bufname == "" then
            return "[No Name]"
          end

          local project_root = root.get()
          local rel = bufname
          if project_root and project_root ~= "" then
            local prefix = project_root .. "/"
            if bufname:sub(1, #prefix) == prefix then
              rel = bufname:sub(#prefix + 1)
            else
              rel = vim.fn.fnamemodify(bufname, ":~:.")
            end
          end

          local icon, icon_color = devicons.get_icon_color(
            vim.fn.fnamemodify(bufname, ":t"),
            vim.fn.fnamemodify(bufname, ":e"),
            { default = true }
          )

          local modified = vim.bo[props.buf].modified

          return {
            { icon, guifg = icon_color },
            { " " },
            { rel, gui = modified and "bold,italic" or "bold" },
            modified and { " ●", guifg = "#e5c07b" } or "",
          }
        end,
      })
    end,
  },
}
