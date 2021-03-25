local Job = require('git.job')
local Hunk = require('git.hunk')

local M = {}

local state = {
    diff_algorithm = 'myers'
}

M.initialize = function()
end

M.tear_down = function()
    state = nil
end

M.diff = function(filepath, callback)
    local errResult = ''
    local hunks = {}

    job = Job:new({
        command = 'git',
        args = {
            '--no-pager',
            '-c',
            'core.safecrlf=false',
            'diff',
            '--color=never',
            '--diff-algorithm=' .. state.diff_algorithm,
            '--patch-with-raw',
            '--unified=0',
            filepath,
        },
        on_stdout = function(_, line)
            if vim.startswith(line, '@@') then
                table.insert(hunks, Hunk:new(filepath, line))
            else
                if #hunks > 0 then
                    lastHunk = hunks[#hunks]
                    lastHunk:add_line(line)
                end
            end
        end,
        on_stderr = function(err, line)
            if err then
                errResult = errResult .. err
            elseif line then
                errResult = errResult .. line
            end
        end,
        on_exit = function()
            if errResult ~= '' then
                return callback(errResult, nil)
            end
            callback(nil, hunks)
        end,
    })
    job:sync()
end

M.diff_files = function(callback)
    local errResult = ''
    local files = {}

    job = Job:new({
        command = 'git',
        args = {
            '--no-pager',
            '-c',
            'core.safecrlf=false',
            'diff',
            '--color=never',
            '--diff-algorithm=' .. state.diff_algorithm,
            '--patch-with-raw',
            '--unified=0',
            '--name-only',
        },
        on_stdout = function(_, file)
            table.insert(files, file)
        end,
        on_stderr = function(err, line)
            if err then
                errResult = errResult .. err
            elseif line then
                errResult = errResult .. line
            end
        end,
        on_exit = function()
            if errResult ~= '' then
                return callback(errResult, nil)
            end
            callback(nil, files)
        end,
    })
    job:sync()
end

return M
