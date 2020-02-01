-- Reimplementation of some pl.pretty functions with a stack depth limit (default 1).
-- NOTE: THIS FILE SUBSTANTIALLY REUSES PENLIGHT CODE AND IS UNDER THE PENLIGHT LICENSE, NOT THE LOVR-ENT LICENSE

namespace "minimal"

local ugly = {}

local append = table.insert
local concat = table.concat
local mfloor, mhuge = math.floor, math.huge
local mtype = math.type
local lexer = require 'pl.lexer'
local original_tostring = tostring
local keywords

-- Patch tostring to format numbers with better precision
-- and to produce cross-platform results for
-- infinite values and NaN.
local function tostring(value)
    if type(value) ~= "number" then
        return original_tostring(value)
    elseif value ~= value then
        return "NaN"
    elseif value == mhuge then
        return "Inf"
    elseif value == -mhuge then
        return "-Inf"
    elseif (_VERSION ~= "Lua 5.3" or mtype(value) == "integer") and mfloor(value) == value then
        return ("%d"):format(value)
    else
        local res = ("%.14g"):format(value)
        if _VERSION == "Lua 5.3" and mtype(value) == "float" and not res:find("%.") then
            -- Number is internally a float but looks like an integer.
            -- Insert ".0" after first run of digits.
            res = res:gsub("%d+", "%0.0", 1)
        end
        return res
    end
end


local function quote_if_necessary (v)
    if not v then return ''
    else
        --AAS
        if v:find ' ' then v = quote_string(v) end
    end
    return v
end

local function is_identifier (s)
    return type(s) == 'string' and s:find('^[%a_][%w_]*$') and not keywords[s]
end

--- Create a string representation of a Lua table.
-- This function never fails, but may complain by returning an
-- extra value. Normally puts out one item per line, using
-- the provided indent; set the second parameter to an empty string
-- if you want output on one line.
-- @tab tbl Table to serialize to a string.
-- @string[opt] space The indent to use.
-- Defaults to two spaces; pass an empty string for no indentation.
-- @bool[opt] not_clever Pass `true` for plain output, e.g `{['key']=1}`.
-- Defaults to `false`.
-- @return a string
-- @return an optional error message
function ugly.write (tbl,space,not_clever,limit)
    if type(tbl) ~= 'table' then
        local res = tostring(tbl)
        if type(tbl) == 'string' then return quote(tbl) end
        return res, 'not a table'
    end
    if not limit then limit = 1 end
    if not keywords then
        keywords = lexer.get_keywords()
    end
    local set = ' = '
    if space == '' then set = '=' end
    space = space or '  '
    local lines = {}
    local line = ''
    local tables = {}


    local function put(s)
        if #s > 0 then
            line = line..s
        end
    end

    local function putln (s)
        if #line > 0 then
            line = line..s
            append(lines,line)
            line = ''
        else
            append(lines,s)
        end
    end

    local function eat_last_comma ()
        local n = #lines
        local lastch = lines[n]:sub(-1,-1)
        if lastch == ',' then
            lines[n] = lines[n]:sub(1,-2)
        end
    end


    local writeit
    writeit = function (t,oldindent,indent,limit)
        local tp = type(t)
        if tp ~= 'string' and  tp ~= 'table' then
            putln(quote_if_necessary(tostring(t))..',')
        elseif tp == 'string' then
            -- if t:find('\n') then
            --     putln('[[\n'..t..']],')
            -- else
            --     putln(quote(t)..',')
            -- end
            --AAS
            putln(quote_string(t) ..",")
        elseif tp == 'table' and limit > 0 then
            if tables[t] then
                putln('<cycle>,')
                return
            end
            tables[t] = true
            local newindent = indent..space
            putln('{')
            local used = {}
            if not not_clever then
                for i,val in ipairs(t) do
                    put(indent)
                    writeit(val,indent,newindent,limit-1)
                    used[i] = true
                end
            end
            for key,val in pairs(t) do
                local tkey = type(key)
                local numkey = tkey == 'number'
                if not_clever then
                    key = tostring(key)
                    put(indent..index(numkey,key)..set)
                    writeit(val,indent,newindent,limit-1)
                else
                    if not numkey or not used[key] then -- non-array indices
                        if tkey ~= 'string' then
                            key = tostring(key)
                        end
                        if numkey or not is_identifier(key) then
                            key = index(numkey,key)
                        end
                        put(indent..key..set)
                        writeit(val,indent,newindent,limit-1)
                    end
                end
            end
            tables[t] = nil
            eat_last_comma()
            putln(oldindent..'},')
        else
            putln(tostring(t)..',')
        end
    end
    writeit(tbl,'',space,limit)
    eat_last_comma()
    return concat(lines,#space > 0 and '\n' or '')
end

--- Dump a Lua table out to a file or stdout.
-- @tab t The table to write to a file or stdout.
-- @string[opt] filename File name to write too. Defaults to writing
-- to stdout.
function ugly.dump (t, filename, limit)
    if not filename then
        print(ugly.write(t, limit))
        return true
    else
        return utils.writefile(filename, ugly.write(t, limit))
    end
end

return ugly