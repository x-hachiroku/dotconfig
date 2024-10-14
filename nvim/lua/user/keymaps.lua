local utils = require('utils')

local function full_width(lines)
    for i, line in ipairs(lines) do
        lines[i] = line:gsub('[\32-\126]', function(char)
            if char == ' ' then
                return vim.fn.nr2char(0x3000)
            end
            return vim.fn.nr2char(char:byte() + 0xFEE0)
        end)
    end
    return lines
end

local function reverse_lies(lines)
    local _lines = {}
    for i = #lines, 1, -1 do
        _lines[#_lines + 1] = lines[i]
    end
    return _lines
end

local function run()
    vim.cmd('w')
    local ft = vim.bo.filetype

    if ft == 'c' then
        vim.cmd('!gcc % -o %<')
        utils.term('term ./%<')
    elseif ft == 'cpp' then
        vim.cmd('!g++ -std=c++11 % -Wall -o %<')
        utils.term('term ./%<')
    elseif ft == 'python' then
        utils.term('term python3 %')
    elseif ft == 'java' then
        vim.cmd('!javac %')
        utils.term('term java %')
    elseif ft == 'javascript' then
        utils.term('term node %')
    elseif ft == 'go' then
        utils.term('term go run %')
    elseif ft == 'sh' then
        utils.term('term bash %')
    elseif ft == 'zsh' then
        utils.term('term zsh %')
    elseif ft == 'markdown' then
        vim.cmd('MarkdownPreview')
    elseif ft == 'tex' then
        vim.cmd('silent! VimtexCompileSS')
    elseif ft == 'arduino' then
        vim.cmd('ArduinoUpload')
    end
end


vim.cmd('cnoreabbrev W  w')
vim.cmd('cnoreabbrev Q  q')
vim.cmd('cnoreabbrev Wq wq')
vim.cmd('cnoreabbrev WQ wq')
vim.cmd('cnoreabbrev Qa qa')
vim.cmd('cnoreabbrev QA qa')

utils.map('n', '<PageDown>', 'J')
utils.map('v', 'J', 'j')

utils.map('n', '<C-p>', 'o<Esc>')
utils.map('i', '<C-o>', '<C-o>o')

utils.map({ 'n', 'v', 'o' }, 'K', 'k')
utils.map({ 'n', 'v', 'o' }, 'E', 'g_l')
utils.map({ 'n', 'v', 'o' }, 'B', '^')

utils.map('n', '<BS>', 'ze')
utils.map('n', '<C-m>', '16zh')
utils.map('n', '<C-i>', '16zl')

utils.map('i', '<C-t>', '<C-v><Tab>')
utils.map({ 'n', 'v', 'o' }, '<C-c>', '<Esc>')
utils.map({ 'n', 'v', 'o' }, 'm', '%')

utils.map('n', 'U', '<C-r>')
utils.map('n', '<C-r>', 'R')
utils.map('n', 'R', run)
utils.map('v', 'R', reverse_lies)

utils.map('v', '<', '<gv')
utils.map('v', '>', '>gv')

utils.map('v', 'W', utils.visual_transform(full_width))
