-- Leader key (must be first)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- AI providers live in lua/ai.lua; NVIM_AI only picks the startup default and
-- can be switched at runtime with <leader>cp or :AI <provider>.

-- Use the currently activated conda env's python for remote plugins (Molten).
-- Falls back to rebal-prod if no env is active.
local conda_prefix = os.getenv("CONDA_PREFIX")
local nvim_py = (conda_prefix and conda_prefix .. "/bin/python")
  or "/opt/data/conda/envs/rebal-prod/bin/python"
if vim.fn.executable(nvim_py) == 1 then
  vim.g.python3_host_prog = nvim_py
end

-- Prefer source-built CLIs over Mason's prebuilt shims when both exist.
-- This avoids glibc mismatches from downloaded binaries on older EC2 images.
local cargo_bin = vim.fn.expand("~/.cargo/bin")
if vim.fn.isdirectory(cargo_bin) == 1 then
  vim.env.PATH = cargo_bin .. ":" .. vim.env.PATH
end
local mason_tree_sitter = vim.fn.stdpath("data") .. "/mason/bin/tree-sitter"
if vim.fn.executable(mason_tree_sitter) == 1 then
  vim.env.PATH = table.concat(vim.tbl_filter(function(part)
    return part ~= vim.fn.stdpath("data") .. "/mason/bin"
  end, vim.split(vim.env.PATH or "", ":", { plain = true })), ":")
end

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- Load plugin specs
require("lazy").setup({
  { import = "plugins" }
})

require("codex_socket").start()
require("core")

-- Editor defaults
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number,line"
vim.opt.guifont = "Iosevka:h12"
