-- encoding.lua: a handful functions for consuming strings of various flavors
-- by Pierre-Yves Gérardy.
-- Released under the Romantic WTF Public License (see the end of the file).

-- Currently, raw bytes, ASCII, printable ASCII and UTF-8 are
-- supported.

-- We provide: 
-- - Charset[x].validate(subject)                -- validator
-- - Charset[x].split_int(subject)               --> table{int}
-- - Charset[x].split_char(subject)              --> table{char}
-- - Charset[x].next_int(subject, index)         -- Lua-style iterator
-- - Charset[x].next_char(subject, index)        -- Lua-style iterator
-- - Charset[x].get_int(subject, index)          -- Julia-style iterator
-- - Charset[x].get_char(subject, index)         -- Julia-style iterator
--
-- Where x is one of "UTF-8", "RAW", "ASCII" or "printable ASCII".
-- Validation is only perfored in .validate(). The other functions
-- assume valid input.

-- See each function in the UTF-8 section for the details.


local s_byte, s_sub, t_insert = string.byte, string.sub, table.insert


--- UTF-8
--

-- Utility function.
-- Modified from code by Kein Hong Man <khman@users.sf.net>,
-- found at http://lua-users.org/wiki/SciteUsingUnicode.
local
function utf8_offset (byte)
         -----------
    if byte < 128 then return 0, byte
    elseif byte < 192 then
        error("Byte values between 0x80 to 0xBF cannot start a multibyte sequence")
    elseif byte < 224 then return 1, byte - 192
    elseif byte < 240 then return 2, byte - 224
    elseif byte < 248 then return 3, byte - 240
    elseif byte < 252 then return 4, byte - 248
    elseif byte < 254 then return 5, byte - 252
    else
        error("Byte values between 0xFE and OxFF cannot start a multibyte sequence")
    end
end



-- success, last_valid_byte = utf8_validate (subject)
--
-- validate a given string.
-- returns two values: 
-- * The first is either true, false or nil, respectively on success, error, or 
--   incomplete subject.
-- * The second is the index of the last byte of the last valid char.

local
function utf8_validate (subject)
         -------------
    local start, finish = 1, #subject
    local offset, char
        = 0
    for i = start,finish do
        b = s_byte(subject,i)
        if offset == 0 then
            char = i
            success, offset = pcall(utf8_offset, b)
            if not success then return false, char - 1 end
        else
            if not (127 < b and b < 192) then
                return false, char - 1
            end
            offset = offset -1
        end
    end
    if offset ~= 0 then return nil, char - 1 end -- Incomplete input.
    return true, finish
end

-- _end, start, char = utf8_next_char(subject, previous_index)
--
--
-- Example:
--     for _end, start, char in utf8_next_char, "˙†ƒ˙©√" do
--         print(cpt)
--     end
-- `start` and `_end` being the bounds of the character, and `cpt` being the 
-- character itself, in string form.

-- Result:
--     ˙
--     †
--     ƒ
--     ˙
--     ©
--     √
local
function utf8_next_char (subject, i)
         --------------
    i = i and i+1 or 1
    if i > #subject then return end
    local offset = utf8_offset(s_byte(subject,i))
    return i + offset, i, s_sub(subject, i, i + offset)
end



--[[
Like the above, but it outputs Unicode code points.
It produces:
    729
    8224
    402
    729
    169
    8730
--]]
local 
function utf8_next_int (subject, i)
         -------------
    i = i and i+1 or 1
    if i > #subject then return end
    local c = s_byte(subject, i)
    local offset, val = utf8_offset(c)
    for i = i+1, i+offset do
        c = s_byte(subject, i)
        val = val * 64 + (c-128)
    end
  return i + offset, i, val
end


-- char, next_index = utf8_get_char(subject, index)

-- Julia-style iterator.
-- More efficient, and easier to use than a Lua-style iterator 
-- outside a for loop. Returns nil at the end of the string.
-- exemple: 
--     utf8_get_char("©j∆", 1) --> "©", 3 -- © is two bytes wide.
--     utf8_get_char("©j∆", 3) --> "©", 4

local
function utf8_get_char(subject, i)
         -------------
    if i > #subject then return end
    local offset = utf8_offset(s_byte(subject,i))
    return s_sub(subject, i, i + offset), i + offset + 1
end

-- Like the above, but returns Unicode code points instead of strings.

local 
function utf8_get_int(subject, i)
         ------------
    if i > #subject then return end
    local c = s_byte(subject, i)
    local offset, val = utf8_offset(c)
    for i = i+1, i+offset do
        c = s_byte(subject, i)
        val = val * 64 + ( c - 128 ) 
    end
    return val, i + offset + 1
end



-- array = utf8_split_char (subject)
--
-- Takes a string, returns an array of characters.
-- exemple:
--     utf8_split_char ("©h∆")--> { "©", "h", "∆" }

local
function utf8_split_char (subject)
         ---------------
    local chars = {}
    for _, _, c in utf8_next_char, subject do
        t_insert(chars,c)
    end
    return chars
end

-- Like the above, but returns Unicode code points instead of strings.

local
function utf8_split_int (subject)
         --------------
    local chars = {}
    for _, _, c in utf8_next_int, subject do
        t_insert(chars,c)
    end
    return chars
end




--- ASCII and binary.
--

-- See UTF-8 above for the API docs.

local
function ascii_validate (subject, start, finish)
        ---------------
    start = start or 1
    finish = finish or #subject

    for i = start,finish do
        b = s_byte(subject,i)
        if b > 127 then return false, i - 1 end
    end
    return true, finish
end

local
function printable_ascii_validate (subject, start, finish)
         ------------------------
    start = start or 1
    finish = finish or #subject

    for i = start,finish do
        b = s_byte(subject,i)
        if 32 > b or b >127 then return false, i - 1 end
    end
    return true, finish
end

local
function binary_validate (subject, start, finish)
         ---------------
    start = start or 1
    finish = finish or #subject
    return true, finish
end

local 
function binary_next_int (subject, i)
         ---------------
    i = i and i+1 or 1
    if i >= #subject then return end
    return i, i, s_sub(subject, i, i)
end

local
function binary_next_char (subject, i)
         ----------------
    i = i and i+1 or 1
    if i > #subject then return end
    return i, i, s_byte(subject,i)
end

local
function binary_split_int (subject)
         ----------------
    local chars = {}
    for i = 1, #subject do
        t_insert(chars, s_byte(subject,i))
    end
    return chars
end

local
function binary_split_char (subject)
         -----------------
    local chars = {}
    for i = 1, #subject do
        t_insert(chars, s_sub(subject,i,i))
    end
    return chars
end

local
function binary_get_int (subject, i)
         --------------
    return s_byte(subject, i), i + 1
end

local
function binary_get_char (subject, i)
         ---------------
    return s_sub(subject, i, i), i + 1
end



--- The table
--

local CharSets = {
    raw = {
        validate   = binary_validate,
        split_char = binary_split_char,
        split_int  = binary_split_int,
        next_char  = binary_next_char,
        next_int   = binary_next_int,
        get_char   = binary_get_char,
        get_int    = binary_get_int
    },

    ASCII = {
        validate   = ascii_validate,
        split_char = binary_split_char,
        split_int  = binary_split_int,
        next_char  = binary_next_char,
        next_int   = binary_next_int,
        get_char   = binary_get_char,
        get_int    = binary_get_int
    },

    ["printable ASCII"] = {
        validate   = printable_ascii_validate,
        split_char = binary_split_char,
        split_int  = binary_split_int,
        next_char  = binary_next_char,
        next_int   = binary_next_int,
        get_char   = binary_get_char,
        get_int    = binary_get_int
    },

    ["UTF-8"] = {
        validate   = utf8_validate,
        split_char = utf8_split_char,
        split_int  = utf8_split_int,
        next_char  = utf8_next_char,
        next_int   = utf8_next_int,
        get_char   = utf8_get_char,
        get_int    = utf8_get_int
    }
}

return CharSets

--                   The Romantic WTF public license.
--                   --------------------------------
--                   a.k.a. version "<3" or simply v3
--
--
--            Dear user,
--
--            encoding.lua
--
--                                             \ 
--                                              '.,__
--                                           \  /
--                                            '/,__
--                                            /
--                                           /
--                                          /
--                       has been          / released
--                  ~ ~ ~ ~ ~ ~ ~ ~       ~ ~ ~ ~ ~ ~ ~ ~ 
--                under  the  Romantic   WTF Public License.
--               ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~`,´ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ 
--               I hereby grant you an irrevocable license to
--                ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
--                  do what the gentle caress you want to
--                       ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~  
--                           with   this   lovely
--                              ~ ~ ~ ~ ~ ~ ~ ~ 
--                               / thing...
--                              /  ~ ~ ~ ~
--                             /    Love,
--                       #    /      '.'
--                       #######      ·
--                       #####
--                       ###
--                       #
--
--            -- Pierre-Yves
--
--
--            P.S.: Even though I poured my heart into this work, 
--                  I _cannot_ provide any warranty regarding 
--                  its fitness for _any_ purpose. You
--                  acknowledge that I will not be held liable
--                  for any damage its use could incur.