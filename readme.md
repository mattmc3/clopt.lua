# clopt.lua

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
local clopt = require "clopt"
local verbose = false

local function handle_verbose(_, value)
  verbose = value
end

local opts = clopt.new_optset()
opts:opt("help", "h", false, "Show help", function()
  print("lua myapp.lua [-h/--help] [-v/--verbose] [-o/--output=ARG] <ARGS>...")
  print(opts:usage())
  os.exit(0)
end)
opts:opt("output", "o", true, "Set output file", function(_, value)
  print("Output file:", value)
end)
opts:opt("verbose", "v", false, "Enable verbosity", handle_verbose)

local function fallback(arg)
  print("Positional or unknown:", arg)
end

opts:parse(arg, fallback)
print(opts:usage())
```

## API

-   `clopt.new_optset()` creates a new option set
-   `opts:opt(name, alias, has_arg, help, handler)` registers an option
    -   `name`: long option name (eg: "output")
    -   `alias`: short option (eg: "o"), or nil
    -   `has_arg`: true if option takes a value
    -   `help`: help string for usage output
    -   `handler`: function called with option name and value (if any)
-   `opts:parse(args, fallback)` parses the args
    -   `args`: argument list (eg: `{...}`)
    -   `fallback`: function called for unknown options and positionals
-   `opts:usage()` returns a formatted usage string

## Example

```lua
opts:opt("verbose", "v", false, "Enable verbose mode", function(_, _)
  print("Verbose mode enabled")
end)
opts:opt("config", "c", true, "Set config file", function(name, value)
  print("Config file:", value)
end)
```

## License

MIT
