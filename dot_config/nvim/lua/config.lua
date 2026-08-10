vim.scriptencoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.helplang = "ja,en"

vim.g.mapleader = " "

vim.opt.title = true
vim.opt.number = true
vim.opt.cursorline = true
-- サインの出入りで本文が左右にずれないよう常時表示する
vim.opt.signcolumn = "yes"
vim.opt.scrolloff = 5
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
-- 行中で Tab / BS を押したときの幅。負値は shiftwidth に追従する指定。
-- tabstop は「既にあるタブ文字の表示幅」で担当が別なので触らない
-- (2 にすると Go や Makefile のインデントまで浅く描画される)
vim.opt.softtabstop = -1

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true

-- undodir のデフォルトが $XDG_STATE_HOME/nvim/undo なのでパスは指定しない
vim.opt.undofile = true

vim.opt.list = true
vim.opt.listchars = { tab = '>>', trail = '-', nbsp = '+' }

