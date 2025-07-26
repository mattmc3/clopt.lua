-- opt.lua - A CLI Option parser

local opt = {}

--[[
Create a new option definition.
@param name string: long option name
@param alias string|nil: short option alias (single character or nil)
@param has_arg boolean: does this option take an argument?
@param handler function: callback for option
@param help string: help text for usage output
@return table: option definition
]]
local function new_opt(id, name, alias, has_arg, help, handler)
	if alias and #alias > 1 then
		error("alias must be a single character or nil")
	end
	return {
		id = id,
		name = name,
		alias = alias,
		has_arg = has_arg,
		help = help or "",
		handler = handler,
	}
end

local OptSet = {}
OptSet.__index = OptSet

--[[
Create a new option set for parsing.
@return OptSet: new option set
]]
function opt.new_optset()
	return setmetatable({ cfg = {}, _opt_id = 0 }, OptSet)
end

--[[
Register an option with a long name and optional short alias.
@param name string: long option name
@param alias string|nil: short option alias (single character or nil)
@param has_arg boolean: does this option take an argument?
@param handler function: callback for option
@param help string: help text for usage output
]]
function OptSet:opt(name, alias, has_arg, help, handler)
	self._opt_id = self._opt_id + 1
	local opt_obj = new_opt(self._opt_id, name, alias, has_arg, help, handler)
	self.cfg["--" .. name] = opt_obj
	if alias and alias ~= "" then
		self.cfg["-" .. alias] = opt_obj
	end
end

--[[
Show usage for all defined options.
@return string: usage text
]]
function OptSet:usage()
	local out = {}
	local opts = {}
	local HELP_COL = 30
	local PREFIX_MAX = HELP_COL - 2
	for k, opt in pairs(self.cfg) do
		if k:sub(1,2) == "--" then
			local short = opt.alias and ("-" .. opt.alias) or ""
			local long = "--" .. opt.name
			local arg = opt.has_arg and " <ARG>" or ""
			local flagstr
			if short ~= "" then
				flagstr = string.format("  %s, %s%s", short, long, arg)
			else
				flagstr = string.format("      %s%s", long, arg)
			end
			local prefix = flagstr
			table.insert(opts, {flagstr = prefix, help = opt.help, wrap = (#prefix + 1 > PREFIX_MAX), id = opt.id})
		end
	end
	-- Sort by insertion order
	table.sort(opts, function(a, b) return a.id < b.id end)
	for _, line in ipairs(opts) do
		if line.wrap then
			table.insert(out, line.flagstr)
			table.insert(out, string.rep(" ", HELP_COL) .. (line.help or ""))
		else
			local pad = HELP_COL - #line.flagstr
			if pad < 1 then pad = 1 end
			table.insert(out, line.flagstr .. string.rep(" ", pad) .. (line.help or ""))
		end
	end
	return table.concat(out, "\n") .. "\n"
end

-- Internal: handle short options, supporting grouping (eg: -abc)
local function handle_short(self, group, args, i, fallback)
	local j = 1
	while j <= #group do
		local ch = group:sub(j, j)
		local key = "-" .. ch
		local cfg = self.cfg[key]
		if not cfg then
			fallback(key)
		elseif cfg.has_arg then
			local val
			if j < #group then
				val = group:sub(j + 1)
				if val:sub(1,1) == "=" then
					val = val:sub(2)
				elseif #val > 0 then
					error("missing argument for " .. key)
				end
				j = #group
			elseif i <= #args then
				val = args[i]
				i = i + 1
			else
				error("missing argument for " .. key)
			end
			cfg.handler(key, val)
			break
		else
			cfg.handler(key, "")
		end
		j = j + 1
	end
	return nil, i
end

-- Internal: handle long options like --foo or --bar=val
local function handle_long(self, arg, args, i, fallback)
	local eq = arg:find("=")
	local name, val
	if eq then
		name = arg:sub(3, eq - 1)
		val = arg:sub(eq + 1)
	else
		name = arg:sub(3)
	end
	local cfg = self.cfg["--" .. name]
	if not cfg then
		fallback(arg)
		return nil, i
	end
	if cfg.has_arg then
		if val ~= nil then
			cfg.handler("--" .. name, val)
		else
			if i <= #args then
				val = args[i]
				i = i + 1
				cfg.handler("--" .. name, val)
			else
				error("missing argument for --" .. name)
			end
		end
	else
		cfg.handler("--" .. name, "")
	end
	return nil, i
end

--[[
Parse CLI arguments using the registered options.
@param args table: argument list
@param fallback function: called for unknown options/positionals
@return nil|string: error message or nil
]]
function OptSet:parse(args, fallback)
	local i = 1
	while i <= #args do
		local arg = args[i]
		i = i + 1

		if arg == "--" then
			-- Everything after this is positional
			while i <= #args do
				fallback(args[i])
				i = i + 1
			end
			break
		elseif arg:sub(1, 2) == "--" then
			-- Long options or "--" to terminate options
			local err
			err, i = handle_long(self, arg, args, i, fallback)
		elseif arg:sub(1, 1) == "-" and #arg > 1 then
			local group = arg:sub(2)
			local err
			err, i = handle_short(self, group, args, i, fallback)
		else
			-- Positional
			fallback(arg)
		end
	end
	return nil
end

return opt
