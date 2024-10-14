local utils = require('utils')

return { 'williamboman/mason-lspconfig.nvim',
    dependencies = {
        { "neovim/nvim-lspconfig" },
        { "mason-org/mason.nvim", opts = {} },
    },

    config = function()
        utils.map('n', 'gh', vim.lsp.buf.hover)
        utils.map('n', 'gd', vim.lsp.buf.definition)
        utils.map('n', 'gD', vim.lsp.buf.declaration)
        utils.map('n', 'gr', vim.lsp.buf.references)
        utils.map('n', 'gi', vim.lsp.buf.implementation)
        utils.map('n', '[d', vim.diagnostic.goto_prev)
        utils.map('n', ']d', vim.diagnostic.goto_next)
        utils.map('n', '<Leader>e', vim.diagnostic.open_float)
        utils.map('n', '<Leader>r', vim.lsp.buf.rename)
    end,

    init = function()
        require('mason').setup()
        require('mason-lspconfig').setup({
            ensure_installed = {
                'bashls',
                'clangd',
                'cssls',
                'dockerls',
                'html',
                'jsonls',
                'ltex',
                'lua_ls',
                'pyright',
                'sqls',
                'ts_ls',
                'yamlls',
            },
            auto_update = true,
            run_on_start = true,
        })
    end
}
