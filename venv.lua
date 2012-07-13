--
-- venv.lua
--
-- Copyright (c) 2012 empr
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- 'Software'), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--

local VENV_HOME = os.getenv('HOME') .. '\\.nya-venv'
local VENV_DIR = VENV_HOME .. '\\venvs'
local CUR_FILE = VENV_HOME .. '\\cur'

local function usage()
    print('usage: venv <command> [option]')
    print('')
    print('commands:')
    print('  init')
    print('  create')
    print('  use')
    print('  list (ls)')
    print('  delete')
    print('  disable')
    print('')
end

local function has_value(tbl, value)
    for k, v in pairs(tbl) do
        if v == value then
            do return true end
        end
    end
    return false
end

local function rmtree(dir)
    for x in nyaos.filefind(dir .. '\\*') do
        if x.name == '.' or x.name == '..' then
            -- do nothing
        else
            local path = dir .. '\\' .. x.name
            if x.directory then
                rmtree(path)
            else
                os.remove(path)
            end
        end
    end
    nyaos.rmdir(dir)
end

local function get_venvs()
    local venvs = {}

    for x in nyaos.dir(VENV_DIR) do
        if x == '.' or x == '..' then
            -- do nothinh
        else
            table.insert(venvs, x)
        end
    end
    return venvs
end

local function get_cur()
    local f, e = io.open(CUR_FILE, 'r')
    local cur

    if f then
        cur = f:read()
        f:close()
        do return cur end
    else
        error(e, 0)
    end
end

local function set_cur(name)
    local f, e = io.open(CUR_FILE, 'w')

    if f then
        f:write(name)
        f:close()
    else
        error(e, 0)
    end
end

local function set_prompt(name)
    local env = '_NYA_VENV_OLD_PROMPT'
    local prompt

    if not os.getenv(env) then
        prompt = nyaos.option.prompt or os.getenv('PROMPT')
        nyaos.exec('set ' .. env .. '=' .. prompt)
    end

    prompt = os.getenv(env)

    if (not name) or name == '' then
        nyaos.option.prompt = prompt
    else
        nyaos.option.prompt = '$e[33;40;1m(' .. name .. ')$e[37;1m' .. prompt
    end
end

local commands = {
    init = function(self)
        nyaos.mkdir(VENV_HOME)
        nyaos.mkdir(VENV_DIR)
        if not nyaos.stat(CUR_FUKE) then
            local f, e = io.open(CUR_FILE, 'w')
            if f then
                f:close()
            else
                error(e, 0)
            end
        end
    end,

    create = function(self, name)
        local venvs = get_venvs()

        if not name then
            error('invalid venv name', 0)
        end

        if has_value(venvs, name) then
            error('"' .. name .. '" already exists.', 0)
        end

        nyaos.exec('virtualenv ' .. VENV_DIR .. '\\' .. name)
    end,

    use = function(self, name)
        local venvs = get_venvs()
        local cur = get_cur()
        local venv_cur_path, venv_new_path

        if not name then
            error('invalid venv name.', 0)
        end

        if not has_value(venvs, name) then
            error('"' .. name .. '" does not exists.', 0)
        end

        if cur then
            venv_cur_path = VENV_DIR .. '\\' .. cur .. '\\Scripts'
            nyaos.exec('set PATH-=' .. venv_cur_path)
        end

        venv_new_path = VENV_DIR .. '\\' .. name .. '\\Scripts'
        nyaos.exec('set PATH+=' .. venv_new_path)

        set_cur(name)

        set_prompt(name)
    end,

    list = function(self)
        local venvs = get_venvs()
        local cur = get_cur()

        for i, x in ipairs(venvs) do
            if x == cur then
                print('* ' .. x)
            else
                print('  ' .. x)
            end
        end
    end,

    ls = function(self)
        self.list()
    end,

    delete = function(self, name)
        local venvs = get_venvs()
        local cur = get_cur()

        if not name then
            error('invald venv name.', 0)
        end

        if not has_value(venvs, name) then
            error('"' .. name .. '" does not exists.', 0)
        end

        rmtree(VENV_DIR .. '\\' .. name)

        if cur == name then
            self.disable()
        end
    end,

    disable = function(self)
        local cur = get_cur()
        local venv_cur_path

        if cur then
            venv_cur_path = VENV_DIR .. '\\' .. cur .. '\\Scripts'
            nyaos.exec('set PATH-=' .. venv_cur_path)
        end

        set_cur('')

        set_prompt()
    end
}

function nyaos.command.venv(cmd, arg)
    if commands[cmd] then
        commands[cmd](commands, arg)
    else
        usage()
    end
end

if nyaos.stat(CUR_FILE) then
    if get_cur() then
        commands:use(get_cur())
    else
        commands:disable()
    end
end
