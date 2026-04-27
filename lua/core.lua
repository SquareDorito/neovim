-- =========================
-- Shared project root helper
-- =========================
local root = require("utils.root")

-- =========================
-- OPTIONS
-- =========================
vim.opt.scrollback = 100000
vim.opt.mouse = "a"
vim.opt.autoread = true

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

-- `rg --files` across project root + ~/notebooks (the code-workspace extras)
local function find_cmd()
  local cmd = { "rg", "--files", "--hidden", "--glob", "!**/.git/**" }
  vim.list_extend(cmd, root.get_all())
  return cmd
end

-- 🔎 Find files (project root + notebooks)
vim.keymap.set("n", "<leader>ff", function()
  builtin.find_files({
    find_command = find_cmd(),
  })
end, { desc = "Find files" })

-- 🔍 Live grep (project root + notebooks)
vim.keymap.set("n", "<leader>fg", function()
  builtin.live_grep({
    search_dirs = root.get_all(),
  })
end, { desc = "Live grep" })

-- ⭐ “Search everything” (file search entry point)
vim.keymap.set("n", "<leader><leader>", function()
  builtin.find_files({
    find_command = find_cmd(),
  })
end, { desc = "Search files (quick)" })

-- 📂 Buffers
vim.keymap.set("n", "<leader>fb", builtin.buffers, {
  desc = "Buffers",
})

-- 🗑️  Close buffers
vim.keymap.set("n", "<leader>bd", "<cmd>%bd<cr>", { desc = "Close all buffers" })
vim.keymap.set("n", "<leader>bo", "<cmd>%bd|e#|bd#<cr>", { desc = "Close other buffers" })

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

local function close_bottom_term_if_open()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_close(term_win, true)
    term_win = nil
    return true
  end
  return false
end

_G.close_bottom_term_if_open = close_bottom_term_if_open

vim.keymap.set("n", "<leader>tt", function()
  if close_bottom_term_if_open() then
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

vim.keymap.set({ "n", "t" }, "<C-_>", function()
  if close_bottom_term_if_open() then
    return
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative ~= "" then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "terminal" then
        vim.api.nvim_win_close(win, true)
      end
    end
  end
end, { desc = "Close bottom term or floating AI panel" })

vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {
  desc = "Exit terminal mode",
})

vim.keymap.set("t", "<C-n>", [[<C-\><C-n>]], {
  desc = "Enter normal mode from terminal",
})

vim.keymap.set("n", "<leader>pr", function()
  local new_root = vim.fn.input("New project root: ", vim.fn.getcwd(), "dir")

  if new_root ~= "" then
    vim.cmd("cd " .. new_root)
    print("Project root set to:", new_root)
  end
end, { desc = "Change project root" })

vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]])
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]])
vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]])
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]])

local function is_file_buffer(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and vim.bo[buf].buftype == ""
    and vim.api.nvim_buf_get_name(buf) ~= ""
end

local function file_windows()
  local wins = vim.api.nvim_tabpage_list_wins(0)

  table.sort(wins, function(a, b)
    return vim.fn.win_id2win(a) < vim.fn.win_id2win(b)
  end)

  return vim.tbl_filter(function(win)
    local buf = vim.api.nvim_win_get_buf(win)
    return is_file_buffer(buf)
  end, wins)
end

local function focus_file_window(index)
  local wins = file_windows()
  local target = wins[index]

  if target and vim.api.nvim_win_is_valid(target) then
    vim.api.nvim_set_current_win(target)
    return
  end

  vim.notify("No file window " .. index .. " in this tab", vim.log.levels.INFO)
end

for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. i, function()
    focus_file_window(i)
  end, {
    desc = "Focus file window " .. i,
  })
end

-- =========================
-- FOCUS EVENTS, CHECKTIME, AUTOSAVE
-- =========================
-- tmux must have `set -g focus-events on` for FocusGained/FocusLost to fire
-- inside a tmux pane.

local focus_group = vim.api.nvim_create_augroup("FocusAndSave", { clear = true })

-- Pull external file changes into the buffer when we re-focus or re-enter it.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = focus_group,
  callback = function()
    -- checktime errors in command-line mode and is meaningless for non-file buffers.
    if vim.fn.mode() ~= "c" and vim.bo.buftype == "" then
      vim.cmd("checktime")
    end
  end,
})

-- Make external reloads visible instead of silent.
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = focus_group,
  callback = function()
    vim.notify("File changed on disk — buffer reloaded", vim.log.levels.WARN)
  end,
})

local function should_autosave(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return false end
  if vim.bo[buf].buftype ~= "" then return false end
  if not vim.bo[buf].modifiable then return false end
  if not vim.bo[buf].modified then return false end
  if vim.api.nvim_buf_get_name(buf) == "" then return false end
  return true
end

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  group = focus_group,
  callback = function(args)
    if should_autosave(args.buf) then
      vim.api.nvim_buf_call(args.buf, function()
        vim.cmd("silent! write")
      end)
    end
  end,
})
