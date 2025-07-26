# opt.lua

A simple Lua command-line option parser. Supports short and long options, grouped short flags, and options with values. Designed to be easy to use and flexible for most CLI scripts.

## Features

-   Short flags (eg: -a -b)
-   Grouped short flags (eg: -abc)
-   Short options with values (eg: -o file.txt or -o=file.txt)
-   Long options (eg: --foo)
-   Long options with values (eg: --bar=val or --bar val)
-   Custom fallback for unknown options and positionals
-   Last value wins for repeated options
-   Usage output with help text

## Usage

```lua
local opt = require "opt"

local opts = opt.new_optset()
opts:opt("help", "h", false, function(name)
  print("Usage: ...")
  os.exit(0)
end, "Show help")
opts:opt("output", "o", true, function(name, value)
  print("Output file:", value)
end, "Set output file")

local function fallback(arg)
  print("Positional or unknown:", arg)
end

opts:parse(arg, fallback)
print(opts:usage())
```

## API

-   `opt.new_optset()` creates a new option set
-   `opts:opt(name, alias, has_arg, handler, help)` registers an option
    -   `name`: long option name (eg: "output")
    -   `alias`: short option (eg: "o"), or nil
    -   `has_arg`: true if option takes a value
    -   `handler`: function called with option name and value (if any)
    -   `help`: help string for usage output
-   `opts:parse(args, fallback)` parses the args
    -   `args`: argument list (eg: `{...}`)
    -   `fallback`: function called for unknown options and positionals
-   `opts:usage()` returns a formatted usage string

## Example

```lua
opts:opt("verbose", "v", false, function(name)
  print("Verbose mode enabled")
end, "Enable verbose mode")
opts:opt("config", "c", true, function(name, value)
  print("Config file:", value)
end, "Set config file")
```

## License

MIT
