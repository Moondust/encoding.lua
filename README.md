# encoding.lua: 
### A handful functions for consuming strings of various flavors 

Currently, raw bytes, ASCII, printable ASCII and UTF-8 are
supported.

## Installation 

via [Moondust](https://github.com/Moondust/moondust).

## Synopsis

```Lua
local encoding = moondust.encoding -- or require"encoding"

encoding[x].validate(subject) -- validator
encoding[x].split_int(subject)               --> table{int}
encoding[x].split_char(subject)              --> table{char}
encoding[x].next_int(subject, index)         -- Lua-style iterator
encoding[x].next_char(subject, index)        -- Lua-style iterator
encoding[x].get_int(subject, index)          -- Julia-style iterator
encoding[x].get_char(subject, index)         -- Julia-style iterator
```


Where x is one of "UTF-8", "RAW", "ASCII" or "printable ASCII".
Validation is only perfored in .validate(). The other functions
assume valid input.

See the UTF-8 section in the source for the detailed usage.

## License

Released under the Romantic WTF Public License.