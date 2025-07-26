package.path = "./src/?.lua;" .. package.path
local opt = require "opt"

local opts = opt.new_optset()

local function usage()
	print("lua example_usage.lua [-h/--help]")
	print(opts:usage())
	os.exit(0)
end

local function opthandler(opt, value)
	print(string.format("Received known option: '%s' with value '%s'.", opt, value))
end

local verbose = false
opts:opt("help", "h", false, "Show help", usage)
opts:opt("output", "o", true, "Set output file", opthandler)
opts:opt("verbose", "v", false, "Enable verbose mode", function()
	verbose = true
	print("Verbose mode enabled")
end)

local function fallback(arg)
	print("Positional or unknown:", arg)
end

opts:parse(arg, fallback)

print(verbose)
