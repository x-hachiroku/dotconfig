vim.cmd('syntax on')

vim.opt.hidden = true
vim.opt.updatetime = 100

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'number'
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.tabstop = 16
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.list = true
vim.opt.listchars = 'tab:· →'
vim.opt.fileencodings = { 'utf-8', 'cp932', 'cp936', 'utf-16' }
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.colorcolumn = '120'

vim.opt.termguicolors = false
vim.opt.incsearch = true
vim.opt.hlsearch = false
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.shellcmdflag = '-ic'

vim.g.neoterm_autoscroll = 1

vim.opt.mouse = ''
vim.opt.guicursor = ''

vim.opt.clipboard = 'unnamedplus'
local osc52 = require('vim.ui.clipboard.osc52')

vim.g.clipboard = {
    name = 'osc52',
    cache_enabled = true,
    copy = {
        ['+'] = osc52.copy('+'),
        ['*'] = osc52.copy('*'),
    },
    paste = {
        ['+'] = osc52.paste('+'),
        ['*'] = osc52.paste('*'),
    }
}
