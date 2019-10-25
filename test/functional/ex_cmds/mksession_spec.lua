local lfs = require('lfs')
local helpers = require('test.functional.helpers')(after_each)

local clear = helpers.clear
local command = helpers.command
local get_pathsep = helpers.get_pathsep
local eq = helpers.eq
local ok = helpers.ok
local funcs = helpers.funcs
local rmdir = helpers.rmdir

local file_prefix = 'Xtest-functional-ex_cmds-mksession_spec'

describe(':mksession', function()
  local session_file = file_prefix .. '.vim'
  local tab_dir = file_prefix .. '.d'

  before_each(function()
    clear()
    lfs.mkdir(tab_dir)
  end)

  after_each(function()
    os.remove(session_file)
    rmdir(tab_dir)
  end)

  it('restores tab-local working directories', function()
    local tmpfile_base = file_prefix .. '-tmpfile'
    local cwd_dir = funcs.getcwd()

    -- :mksession does not save empty tabs, so create some buffers.
    command('edit ' .. tmpfile_base .. '1')
    command('tabnew')
    command('edit ' .. tmpfile_base .. '2')
    command('tcd ' .. tab_dir)
    command('tabfirst')
    command('mksession ' .. session_file)

    -- Create a new test instance of Nvim.
    clear()

    command('source ' .. session_file)
    -- First tab should have the original working directory.
    command('tabnext 1')
    eq(cwd_dir, funcs.getcwd())
    -- Second tab should have the tab-local working directory.
    command('tabnext 2')
    eq(cwd_dir .. get_pathsep() .. tab_dir, funcs.getcwd())
  end)

  it('restores buffers when using tab-local working directories', function()
    local tmpfile_base = file_prefix .. '-tmpfile'
    local cwd_dir = funcs.getcwd()
    local session_path = cwd_dir .. get_pathsep() .. session_file

    command('edit ' .. tmpfile_base .. '1')
    command('tcd ' .. tab_dir)
    command('tabnew')
    command('edit ' .. cwd_dir .. get_pathsep() .. tmpfile_base .. '2')
    command('tabfirst')
    command('mksession ' .. session_path)

    -- Create a new test instance of Nvim.
    clear()

    -- Use :silent to avoid press-enter prompt due to long path
    command('silent source ' .. session_path)
    command('tabnext 1')
    eq(cwd_dir .. get_pathsep() .. tmpfile_base .. '1', funcs.expand('%:p'))
    command('tabnext 2')
    eq(cwd_dir .. get_pathsep() .. tmpfile_base .. '2', funcs.expand('%:p'))
  end)

  it('restores the cwd of processes in terminal buffers', function()
    local cwd_dir = funcs.getcwd()
    local session_path = cwd_dir .. get_pathsep() .. session_file

    command('cd ' .. tab_dir)
    command('terminal ' .. 'echo $PWD')
    command('cd ' .. cwd_dir)
    command('mksession ' .. session_path)

    clear()

    command('silent source ' .. session_path)

    local expected_dir = cwd_dir .. get_pathsep() .. tab_dir
    local expected_dir_pattern, _ = expected_dir:gsub('%.', '%%.'):gsub('%-', '%%-')

    ok(nil ~= funcs.expand('%:p'):find(expected_dir_pattern))
  end)
end)
