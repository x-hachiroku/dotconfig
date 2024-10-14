vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'html', 'json', 'xml', 'yaml', 'markdown', 'tex' },
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.colorcolumn = '120'
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'markdown', 'tex' },
    callback = function()
        vim.opt_local.textwidth = 120
    end,
})

vim.api.nvim_create_autocmd('TermOpen', {
    pattern = '*',
    command = 'startinsert',
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    callback = function(ev)
        local map = function(mode, src, dst)
            vim.keymap.set(mode, src, dst, { buffer = ev.buf, noremap = true } )
        end
        map('n', '<Leader>1', [[:s/#\+ \?//e<CR>I# <Esc>$]])
        map('i', '<Leader>1', [[<Esc>:s/#\+ \?//e<CR>I# <Esc>A]])
        map('n', '<Leader>2', [[:s/#\+ \?//e<CR>I## <Esc>$]])
        map('i', '<Leader>2', [[<Esc>:s/#\+ \?//e<CR>I## <Esc>A]])
        map('n', '<Leader>3', [[:s/#\+ \?//e<CR>I### <Esc>$]])
        map('i', '<Leader>3', [[<Esc>:s/#\+ \?//e<CR>I### <Esc>A]])
        map('n', '<Leader>4', [[:s/#\+ \?//e<CR>I#### <Esc>$]])
        map('i', '<Leader>4', [[<Esc>:s/#\+ \?//e<CR>I#### <Esc>A]])

        map('n', '<Leader><CR>',
            'o<div style=\'page-break-after: always; break-after: page;\'></div><CR><Esc>',
            { buffer = ev.buf, noremap = true }
        )
    end,
})
