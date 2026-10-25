vim.scriptencoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.helplang = "ja,en"

vim.g.mapleader = " "

vim.opt.title = true
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 5
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
-- 負値は shiftwidth に追従する
vim.opt.softtabstop = -1

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.undofile = true

vim.opt.list = true
vim.opt.listchars = { tab = '>>', trail = '-', nbsp = '+' }

