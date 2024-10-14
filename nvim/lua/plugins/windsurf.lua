local map = function(mode, trigger, action)
    vim.g.codeium_no_map_tab = 1
    vim.keymap.set(mode, trigger, action, { noremap = true, silent = true, expr = true })
end

return { 'Exafunction/windsurf.vim',
    config = function ()
        map('i', '<C-f>', function() return vim.fn['codeium#Accept']() end)
        map('i', '<C-x>', function() return vim.fn['codeium#Clear']() end)
        map('i', '<C-;>', function() return vim.fn['codeium#CycleCompletions'](1) end)
    end
}
