vim.g.colors_name = 'hikari'

vim.opt.cursorline = true

local hl = vim.api.nvim_set_hl

hl(0, 'CursorLine', { cterm = { underline = true }})

hl(0, 'LineNr',      { ctermfg = 103 })
hl(0, 'Search',      {                ctermbg = 11 })
hl(0, 'Visual',      { ctermfg = nil, ctermbg = 189 })
hl(0, 'ColorColumn', {                ctermbg = 189 })

hl(0, 'Type',        { ctermfg = 25 })
hl(0, 'Constant',    { ctermfg = 22 })
hl(0, 'Comment',     { ctermfg = 244 })
hl(0, 'PreProc',     { ctermfg = 25 })
hl(0, 'Statement',   { ctermfg = 166 })

hl(0, 'DiffAdd',    { ctermfg = 103, ctermbg = 113})
hl(0, 'DiffChange', { ctermfg = 103, ctermbg = 214})
hl(0, 'DiffDelete', { ctermfg = 103, ctermbg = 210})

hl(0, 'NormalFloat', { ctermfg = 0, ctermbg = 7 })

hl(0, 'TrailingSpace', { ctermbg = 244 })
vim.cmd([[match TrailingSpace /\s\+$/]])
