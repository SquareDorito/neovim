-- =========================
-- Shared project root helper
-- =========================
local root = require("utils.root")

-- =========================
-- PROJECT NAVIGATION
-- =========================

-- 📁 Open project root in Neo-tree
vim.keymap.set("n", "<leader>p", function()
  require("neo-tree.command").execute({
    action = "show",
    dir = root.get(),
  })
end, { desc = "Open project root (Neo-tree)" })

-- 🧭 Open Neovim config project
vim.keymap.set("n", "<leader>nc", function()
  local config_root = vim.fn.expand("~/.config/nvim")

  require("neo-tree.command").execute({
    action = "show",
    dir = config_root,
  })

  vim.cmd("edit " .. config_root .. "/init.lua")
end, { desc = "Open Neovim config project" })

-- =========================
-- TELESCOPE SEARCH (project-aware)
-- =========================
local builtin = require("telescope.builtin")

-- 🔎 Find files (project root)
vim.keymap.set("n", "<leader>ff", function()
  builtin.find_files({
    cwd = root.get(),
  })
end, { desc = "Find files" })

-- 🔍 Live grep (search text)
vim.keymap.set("n", "<leader>fg", function()
  builtin.live_grep({
    cwd = root.get(),
  })
end, { desc = "Live grep" })

-- ⭐ “Search everything” (file search entry point)
vim.keymap.set("n", "<leader><leader>", function()
  builtin.find_files({
    cwd = root.get(),
  })
end, { desc = "Search files (quick)" })

-- 📂 Buffers
vim.keymap.set("n", "<leader>fb", builtin.buffers, {
  desc = "Buffers",
})

-- 🕘 Recent files
vim.keymap.set("n", "<leader>fr", builtin.oldfiles, {
  desc = "Recent files",
})

-- =========================
-- OPTIONAL: clean exit behavior (safe version)
-- =========================
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local wins = vim.api.nvim_tabpage_list_wins(0)

    if #wins == 1 then
      local buf = vim.api.nvim_win_get_buf(wins[1])
      local ft = vim.bo[buf].filetype

      if ft == "neo-tree" then
        vim.cmd("quit")
      end
    end
  end,
})

vim.diagnostic.config({
  virtual_text = true,  -- inline messages
  signs = true,         -- gutter icons (red/yellow)
  underline = true,     -- squiggles
  update_in_insert = false,
  severity_sort = true,
})


vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    vim.lsp.buf.format({
      timeout_ms = 2000,
      filter = function(client)
        -- avoid conflicts
        local blacklist = {
          tsserver = true,
        }
        return not blacklist[client.name]
      end,
    })
  end,
})

local term_buf = nil
local term_win = nil

vim.keymap.set("n", "<leader>tt", function()
  -- If terminal is open, close it
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_close(term_win, true)
    term_win = nil
    return
  end

  -- Reuse existing terminal buffer if it exists
  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    vim.cmd("botright 12split")
    term_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(term_win, term_buf)
  else
    vim.cmd("botright 12split | terminal")
    term_win = vim.api.nvim_get_current_win()
    term_buf = vim.api.nvim_get_current_buf()
  end

  vim.cmd("startinsert")
end, { desc = "Toggle bottom terminal" })

vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {
  desc = "Exit terminal mode",
})

vim.keymap.set("n", "<leader>pr", function()
  local new_root = vim.fn.input("New project root: ", vim.fn.getcwd(), "dir")

  if new_root ~= "" then
    vim.cmd("cd " .. new_root)
    print("Project root set to:", new_root)
  end
end, { desc = "Change project root" })

vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {
  desc = "Exit terminal mode",
})

vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]])
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]])
vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]])
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]])
