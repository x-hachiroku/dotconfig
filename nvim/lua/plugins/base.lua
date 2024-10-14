local utils = require('utils')

return {
    { 'andymass/vim-matchup' },
    { 'fidian/hexmode' },
    { 'gcmt/wildfire.vim' },
    { 'tpope/vim-surround' },

    { 'godlygeek/tabular',
        init = function()
            utils.map('v', 'T', ':Tabularize /')
            utils.map('v', 't', ':Tabularize /\\zs<Left><Left><Left>')
        end
    },

    { 'mhinz/vim-signify',
        init = function()
            vim.g.signify_sign_add = ""
            vim.g.signify_sign_change = ""
            vim.g.signify_sign_delete = ""
            vim.g.signify_sign_change_delete = ""
            vim.g.signify_sign_delete_first_line = ""
            vim.g.signify_sign_show_count = 0
            vim.g.signify_number_highlight = 1

            vim.cmd('cnoreabbrev rev SignifyHunkUndo')
            utils.map('n', '??', ':SignifyHunkDiff<CR>')
        end,
    },

    { 'mg979/vim-visual-multi',
        init = function()
            vim.g.VM_default_mappings = 0
            vim.g.VM_maps = {
                ['Undo'] = 'u',
                ['Redo'] = 'U',
                ['Add Cursor Down'] = '<C-Down>',
                ['Add Cursor Up']   = '<C-Up>',
                ['Find Under']      = '<C-f>',
            }
        end,
    },

    { 'nvim-mini/mini.icons', version = false,
        config = function() require('mini.icons').setup() end,
    },
    { 'nvim-mini/mini.pairs', version = false,
        config = function()
            require('mini.pairs').setup({
                mappings = {
                    ["'"] = false,
                    ['"'] = false,
                },
            })
        end,
    },

    { 'lervag/vimtex',
        ft = { 'tex' },
        init = function()
            vim.g.vimtex_quickfix_open_on_warning = 0
            vim.g.vimtex_compiler_latexmk = { options = { '--shell-escape', '--auxdir=/tmp/tex' } }
        end,
    },

    { "iamcco/markdown-preview.nvim",
        ft = { "markdown" },
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        build = "cd app && npm install; git restore .",
        init = function() vim.g.mkdp_filetypes = { "markdown" } end,
    },
}
