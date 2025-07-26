local opt = require "opt"

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
		local opts = opt.new_opt_set()
		opts:opt("a", function(name)
			table.insert(parsed.flags, name)
		end)
		assert.is_nil(opts:parse({ "-a" }, fallback))
		assert.are.same({ "-a" }, parsed.flags)
	end)

	it("handles grouped short flags", function()
		local opts = opt.new_opt_set()
		opts:opt("a", function(n) table.insert(parsed.flags, n) end)
		opts:opt("b", function(n) table.insert(parsed.flags, n) end)
		opts:opt("c", function(n) table.insert(parsed.flags, n) end)
		assert.is_nil(opts:parse({ "-abc" }, fallback))
		assert.are.same({ "-a", "-b", "-c" }, parsed.flags)
	end)

	it("handles short option with value", function()
		local opts = opt.new_opt_set()
		opts:arg("o", function(n, v)
			parsed.args[n] = v
		end)
		assert.is_nil(opts:parse({ "-o", "outfile.txt" }, fallback))
		assert.are.same({ ["-o"] = "outfile.txt" }, parsed.args)
	end)

	it("handles short option with =value", function()
		local opts = opt.new_opt_set()
		opts:arg("o", function(n, v)
			parsed.args[n] = v
		end)
		assert.is_nil(opts:parse({ "-o=outfile.txt" }, fallback))
		assert.are.same({ ["-o"] = "outfile.txt" }, parsed.args)
	end)

	it("rejects grouped options when value arg is in middle", function()
		local opts = opt.new_opt_set()
		opts:opt("a", function(n) table.insert(parsed.flags, n) end)
		opts:arg("b", function(n, v) parsed.args[n] = v end)
		local err = opts:parse({ "-ba", "val" }, fallback)
		assert.are.equal("missing argument for -b", err)
	end)

	it("handles long option with =", function()
		local opts = opt.new_opt_set()
		local err = opts:parse({ "--foo=bar" }, fallback)
		assert.are.equal("unsupported long option: --foo=bar", err)
	end)

	it("handles long option without =", function()
		local opts = opt.new_opt_set()
		local err = opts:parse({ "--foo", "bar" }, fallback)
		assert.are.equal("unsupported long option: --foo", err)
	end)

	it("stops parsing after --", function()
		local opts = opt.new_opt_set()
		opts:opt("a", function(n) table.insert(parsed.flags, n) end)
		assert.is_nil(opts:parse({ "-a", "--", "-b", "positional" }, fallback))
		assert.are.same({ "-a" }, parsed.flags)
		assert.are.same({ "-b", "positional" }, parsed.positionals)
	end)

	it("calls fallback on unknown short option", function()
		local opts = opt.new_opt_set()
		assert.is_nil(opts:parse({ "-x", "foo" }, fallback))
		assert.are.same({ "-x", "foo" }, parsed.positionals)
	end)

	it("handles multiple mixed arguments", function()
		local opts = opt.new_opt_set()
		opts:opt("a", function(n) table.insert(parsed.flags, n) end)
		opts:opt("l", function(n) table.insert(parsed.flags, n) end)
		opts:arg("o", function(n, v) parsed.args[n] = v end)

		local input = { "-al", "-o", "file.txt", "main.c" }
		assert.is_nil(opts:parse(input, fallback))

		assert.are.same({ "-a", "-l" }, parsed.flags)
		assert.are.same({ ["-o"] = "file.txt" }, parsed.args)
		assert.are.same({ "main.c" }, parsed.positionals)
	end)

	it("handles value option at end of grouped short flags", function()
		local opts = opt.new_opt_set()
		opts:opt("x", function(n) table.insert(parsed.flags, n) end)
		opts:arg("o", function(n, v) parsed.args[n] = v end)

		assert.is_nil(opts:parse({ "-xo", "out.txt" }, fallback))
		assert.are.same({ "-x" }, parsed.flags)
		assert.are.same({ ["-o"] = "out.txt" }, parsed.args)
	end)

	it("errors if value option at end is missing argument", function()
		local opts = opt.new_opt_set()
		opts:arg("o", function(n, v) parsed.args[n] = v end)
		local err = opts:parse({ "-o" }, fallback)
		assert.are.equal("missing argument for -o", err)
	end)

end)
