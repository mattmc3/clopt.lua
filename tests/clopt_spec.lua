local clopt = require "clopt"

describe("opt parser", function()
	local parsed

	local function reset()
		parsed = {
			flags = {},
			args = {},
			positionals = {},
			errors = {}
		}
	end

	local function fallback(arg)
		table.insert(parsed.positionals, arg)
	end

	before_each(function()
		reset()
	end)

	it("handles simple short flags", function()
		local opts = clopt.new_optset()
		opts:opt("a", "a", false, "Enable A mode", function(name)
			table.insert(parsed.flags, name)
		end)
		assert.is_nil(opts:parse({ "-a" }, fallback))
		assert.are.same({ "-a" }, parsed.flags)
	end)

	it("handles grouped short flags", function()
		local opts = clopt.new_optset()
		opts:opt("a", "a", false, "A flag", function(n) table.insert(parsed.flags, n) end)
		opts:opt("b", "b", false, "B flag", function(n) table.insert(parsed.flags, n) end)
		opts:opt("c", "c", false, "C flag", function(n) table.insert(parsed.flags, n) end)
		assert.is_nil(opts:parse({ "-abc" }, fallback))
		assert.are.same({ "-a", "-b", "-c" }, parsed.flags)
	end)

	it("handles short option with value", function()
		local opts = clopt.new_optset()
		opts:opt("o", "o", true, "Output file", function(n, v)
			parsed.args[n] = v
		end)
		assert.is_nil(opts:parse({ "-o", "outfile.txt" }, fallback))
		assert.are.same({ ["-o"] = "outfile.txt" }, parsed.args)
	end)

	it("handles short option with =value", function()
		local opts = clopt.new_optset()
		opts:opt("o", "o", true, "Output file", function(n, v)
			parsed.args[n] = v
		end)
		assert.is_nil(opts:parse({ "-o=outfile.txt" }, fallback))
		assert.are.same({ ["-o"] = "outfile.txt" }, parsed.args)
	end)

	it("rejects grouped options when value arg is in middle", function()
		local opts = clopt.new_optset()
		opts:opt("a", "a", false, "A flag", function(n) table.insert(parsed.flags, n) end)
		opts:opt("b", "b", true, "B option", function(n, v) parsed.args[n] = v end)
		assert.error(function()
			opts:parse({ "-ba", "val" }, fallback)
		end, "missing argument for -b")
	end)

	it("handles long flag", function()
		local opts = clopt.new_optset()
		opts:opt("foo", nil, false, "Foo flag", function(n)
			table.insert(parsed.flags, n)
		end)
		assert.is_nil(opts:parse({ "--foo" }, fallback))
		assert.are.same({ "--foo" }, parsed.flags)
	end)

	it("handles long option with =value", function()
		local opts = clopt.new_optset()
		opts:opt("bar", nil, true, "Bar option", function(n, v)
			parsed.args[n] = v
		end)
		assert.is_nil(opts:parse({ "--bar=val" }, fallback))
		assert.are.same({ ["--bar"] = "val" }, parsed.args)
	end)

	it("handles long option with value as next arg", function()
		local opts = clopt.new_optset()
		opts:opt("bar", nil, true, "Bar option", function(n, v)
			parsed.args[n] = v
		end)
		assert.is_nil(opts:parse({ "--bar", "val" }, fallback))
		assert.are.same({ ["--bar"] = "val" }, parsed.args)
	end)

	it("errors if long option missing argument", function()
		local opts = clopt.new_optset()
		opts:opt("bar", nil, true, "Bar option", function(n, v) parsed.args[n] = v end)
		assert.error(function()
			opts:parse({ "--bar" }, fallback)
		end, "missing argument for --bar")
	end)

	it("handles unknown long option via fallback", function()
		local opts = clopt.new_optset()
		assert.is_nil(opts:parse({ "--unknown", "foo" }, fallback))
		assert.are.same({ "--unknown", "foo" }, parsed.positionals)
	end)

	it("stops parsing after --", function()
		local opts = clopt.new_optset()
		opts:opt("a", "a", false, "A flag", function(n) table.insert(parsed.flags, n) end)
		assert.is_nil(opts:parse({ "-a", "--", "-b", "positional" }, fallback))
		assert.are.same({ "-a" }, parsed.flags)
		assert.are.same({ "-b", "positional" }, parsed.positionals)
	end)

	it("calls fallback on unknown short option", function()
		local opts = clopt.new_optset()
		assert.is_nil(opts:parse({ "-x", "foo" }, fallback))
		assert.are.same({ "-x", "foo" }, parsed.positionals)
	end)

	it("handles multiple mixed arguments", function()
		local opts = clopt.new_optset()
		opts:opt("a", "a", false, "A flag", function(n) table.insert(parsed.flags, n) end)
		opts:opt("l", "l", false, "L flag", function(n) table.insert(parsed.flags, n) end)
		opts:opt("o", "o", true, "Output file", function(n, v) parsed.args[n] = v end)

		local input = { "-al", "-o", "file.txt", "main.c" }
		assert.is_nil(opts:parse(input, fallback))

		assert.are.same({ "-a", "-l" }, parsed.flags)
		assert.are.same({ ["-o"] = "file.txt" }, parsed.args)
		assert.are.same({ "main.c" }, parsed.positionals)
	end)

	it("handles value option at end of grouped short flags", function()
		local opts = clopt.new_optset()
		opts:opt("x", "x", false, "X flag", function(n) table.insert(parsed.flags, n) end)
		opts:opt("o", "o", true, "Output file", function(n, v) parsed.args[n] = v end)

		assert.is_nil(opts:parse({ "-xo", "out.txt" }, fallback))
		assert.are.same({ "-x" }, parsed.flags)
		assert.are.same({ ["-o"] = "out.txt" }, parsed.args)
	end)

	it("errors if value option at end is missing argument", function()
		local opts = clopt.new_optset()
		opts:opt("o", "o", true, "Output file", function(n, v) parsed.args[n] = v end)
		assert.error(function()
			opts:parse({ "-o" }, fallback)
		end, "missing argument for -o")
	end)

	it("last value wins for repeated short options", function()
		local opts = clopt.new_optset()
		opts:opt("o", "o", true, "Output file", function(n, v) parsed.args[n] = v end)
		local input = {"-o", "1", "-o", "2", "-o", "3"}
		assert.is_nil(opts:parse(input, fallback))
		assert.are.equal("3", parsed.args["-o"])
	end)

	it("last value wins for repeated long options", function()
		local opts = clopt.new_optset()
		opts:opt("foo", nil, true, "Foo option", function(n, v) parsed.args[n] = v end)
		local input = {"--foo", "1", "--foo", "2", "--foo", "3"}
		assert.is_nil(opts:parse(input, fallback))
		assert.are.equal("3", parsed.args["--foo"])
	end)

	it("handles grouped short flags with =value at end", function()
		local opts = clopt.new_optset()
		opts:opt("a", "a", false, "A flag", function(n) table.insert(parsed.flags, n) end)
		opts:opt("b", "b", false, "B flag", function(n) table.insert(parsed.flags, n) end)
		opts:opt("c", "c", true, "C option", function(n, v) parsed.args[n] = v end)
		assert.is_nil(opts:parse({ "-abc=xyz" }, fallback))
		assert.are.same({ "-a", "-b" }, parsed.flags)
		assert.are.same({ ["-c"] = "xyz" }, parsed.args)
	end)

	it("shows usage for all options", function()
		local opts = clopt.new_optset()
		opts:opt("foo", "f", false, "Foo flag", function() end)
		opts:opt("bar", nil, true, "Bar option", function() end)
		opts:opt("baz", "z", true, "Baz option", function() end)
		local expected = [[  -f, --foo                   Foo flag
      --bar <ARG>             Bar option
  -z, --baz <ARG>             Baz option
]]
		local usage = opts:usage()
		assert.are.equal(expected, usage)
	end)

	it("wraps help text for long flag names", function()
		local opts = clopt.new_optset()
		opts:opt("really-long-flag-name-that-exceeds-width", "r", true, "This help should be wrapped to the next line.", function() end)
		local expected = [[  -r, --really-long-flag-name-that-exceeds-width <ARG>
                              This help should be wrapped to the next line.
]]
		local usage = opts:usage()
		assert.are.equal(expected, usage)
	end)

	it("does not show help for undocumented options", function()
		local opts = clopt.new_optset()
		opts:opt("foo", "f", false, nil, function() end)
		opts:opt("bar", nil, true, "Bar option", function() end)
		local expected = [[  -f, --foo
      --bar <ARG>             Bar option
]]
		local usage = opts:usage()
		assert.are.equal(expected, usage)
	end)

end)
