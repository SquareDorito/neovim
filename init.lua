-- Leader key (must be first)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- AI assistant provider: "codex" or "claude"
vim.g.ai_provider = os.getenv("NVIM_AI") or "claude"

-- Use the currently activated conda env's python for remote plugins (Molten).
-- Falls back to rebal-prod if no env is active.
local conda_prefix = os.getenv("CONDA_PREFIX")
local nvim_py = (conda_prefix and conda_prefix .. "/bin/python")
  or "/opt/data/conda/envs/rebal-prod/bin/python"
if vim.fn.executable(nvim_py) == 1 then
  vim.g.python3_host_prog = nvim_py
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

require("core")

-- Editor defaults
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.cmd("colorscheme onedark")
