-- opt.lua - Flag parser with grouped short option support

local opt = {}

--[[
Create a new option definition.
@param name string: long option name
@param alias string|nil: short option alias (single character or nil)
@param has_arg boolean: does this option take an argument?
@param handler function: callback for option
@return table: option definition
]]
local function new_opt(name, alias, has_arg, handler)
	if alias and #alias > 1 then
		error("alias must be a single character or nil")
	end
	return {
		name = name,
		alias = alias,
		has_arg = has_arg,
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
	return setmetatable({ cfg = {} }, OptSet)
end

--[[
Register an option with a long name and optional short alias.
@param name string: long option name
@param alias string|nil: short option alias (single character or nil)
@param has_arg boolean: does this option take an argument?
@param handler function: callback for option
]]
function OptSet:opt(name, alias, has_arg, handler)
	self.cfg["--" .. name] = new_opt(name, alias, has_arg, handler)
	if alias and alias ~= "" then
		self.cfg["-" .. alias] = self.cfg["--" .. name]
	end
end

-- Internal: handle short options, supporting grouping (eg: -abc)
local function handle_short(self, group, args, i, fallback)
	local j = 1
	while j <= #group do
		local ch = group:sub(j, j)
		local key = "-" .. ch
		local cfg = self.cfg[key]
		if not cfg then
			local err = fallback(key)
			if err then return err, i end
		elseif cfg.has_arg then
			local val
			if j < #group then
				val = group:sub(j + 1)
				if val:sub(1,1) == "=" then
					val = val:sub(2)
				elseif #val > 0 then
					return "missing argument for " .. key, i
				end
				j = #group
			elseif i <= #args then
				val = args[i]
				i = i + 1
			else
				return "missing argument for " .. key, i
			end
			local err = cfg.handler(key, val)
			if err then return err, i end
			break
		else
			local err = cfg.handler(key, "")
			if err then return err, i end
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
		-- Pass unknown long option to fallback
		local err = fallback(arg)
		if err then return err, i end
		return nil, i
	end
	if cfg.has_arg then
		if val ~= nil then
			local err = cfg.handler("--" .. name, val)
			if err then return err, i end
		else
			if i <= #args then
				val = args[i]
				i = i + 1
				local err = cfg.handler("--" .. name, val)
				if err then return err, i end
			else
				return "missing argument for --" .. name, i
			end
		end
	else
		local err = cfg.handler("--" .. name, "")
		if err then return err, i end
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
				local err = fallback(args[i])
				if err then return err end
				i = i + 1
			end
			break
		elseif arg:sub(1, 2) == "--" then
			-- Long options or "--" to terminate options
			local err
			err, i = handle_long(self, arg, args, i, fallback)
			if err then return err end
		elseif arg:sub(1, 1) == "-" and #arg > 1 then
			local group = arg:sub(2)
			local err
			err, i = handle_short(self, group, args, i, fallback)
			if err then return err end
		else
			-- Positional
			local err = fallback(arg)
			if err then return err end
		end
	end
	return nil
end

return opt
