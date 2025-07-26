-- opt.lua - Flag parser with grouped short option support

local opt = {}

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

function opt.new_optset()
	return setmetatable({ cfg = {} }, OptSet)
end

function OptSet:opt(name, alias, has_arg, handler)
	self.cfg["--" .. name] = new_opt(name, alias, has_arg, handler)
	if alias and alias ~= "" then
		self.cfg["-" .. alias] = self.cfg["--" .. name]
	end
end

local function handle_group(self, group, args, i, fallback)
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

-- Parse CLI args
function OptSet:parse(args, fallback)
	local i = 1
	while i <= #args do
		local arg = args[i]
		i = i + 1

		if arg:sub(1, 2) == "--" then
			-- Long options or "--" to terminate options
			if arg == "--" then
				-- Everything after this is positional
				while i <= #args do
					local err = fallback(args[i])
					if err then return err end
					i = i + 1
				end
				break
			else
				local err
				err, i = handle_long(self, arg, args, i, fallback)
				if err then return err end
			end
		elseif arg:sub(1, 1) == "-" and #arg > 1 then
			local group = arg:sub(2)
			local err
			err, i = handle_group(self, group, args, i, fallback)
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
