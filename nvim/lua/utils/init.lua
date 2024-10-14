local M = {}

M.map = function(mode, trigger, action, options)
    local opts = { noremap = true, silent = true }
    if options then
        opts = vim.tbl_extend('force', opts, options)
    end
    vim.keymap.set(mode, trigger, action, opts)
end

M.visual_transform = function(transform)
    return function()
        local buf = vim.api.nvim_get_current_buf()
        local start_pos = vim.fn.getpos('v')
        local end_pos = vim.fn.getpos('.')
        local start_row = start_pos[2]
        local start_col = start_pos[3]
        local end_row = end_pos[2]
        local end_col = end_pos[3]
        if end_row < start_row or (end_row == start_row and end_col < start_col) then
            start_row, end_row = end_row, start_row
            start_col, end_col = end_col, start_col
        end
        start_row = start_row - 1
        start_col = start_col - 1
        end_row = end_row - 1

        local lines = vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})
        lines = transform(lines)

        vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, lines)
    end
end

M.term = function(cmd)
    vim.cmd('split')
    vim.cmd('wincmd j')
    vim.cmd('set nonu')
    vim.cmd('resize -4')
    vim.cmd(cmd)
end

return M
