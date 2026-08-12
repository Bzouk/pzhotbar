
-- this Code is from https://github.com/blind-coder/pz-bcUtils/tree/master 

local bcUtils = {}

bcUtils.tableIsEmpty = function(o) -- {{{ check if a passed table is empty (ie: {} )
	for _,_ in pairs(o) do
		return false
	end
	return true
end
-- }}}

-- }}}
bcUtils.split = function(string, sep) -- {{{ split a string, regex style
	sep = sep or ":";
	local pattern = string.format("([^%s]+)", sep);
	local fields = {};
	string:gsub(pattern, function(c) fields[#fields+1] = c end);
	return fields
end
-- }}}

bcUtils.readINI = function(filename)--{{{
	local retVal = {};
	local rvptr = retVal;
	local f = getFileReader(filename, false);
	if not f then return retVal end;

	local line = "1";
	local currentCat = "unknown";

	while line do
		line = f:readLine();
		if line then
			if luautils.stringStarts(line, "[") then
				currentCat = string.match(line, "[a-zA-Z0-9/ \.]+");
				rvptr = retVal;
				for _,cat in ipairs(bcUtils.split(currentCat, "/")) do
					if not rvptr[cat] then rvptr[cat] = {} end
					rvptr = rvptr[cat];
				end
			else
				local kv = bcUtils.split(line, "=");
				rvptr[kv[1]] = kv[2];
			end
		end
	end
	return retVal;
end
--}}}

bcUtils.writeINItable = function(fd, table, parentCategory)--{{{
	local category;
	for catID,catVal in pairs(table) do
		if parentCategory then
			category = parentCategory.."/"..catID;
		else
			category = catID;
		end
		fd:write("["..category.."]\n");
		for k,v in pairs(catVal) do
			if type(v) == "table" then
				local a = {};
				a[k] = v;
				bcUtils.writeINItable(fd, a, category);
			else
				fd:write(tostring(k).."="..tostring(v).."\n");
			end
		end
	end
end
--}}}
bcUtils.writeINI = function(filename, content)--{{{
	local fd = getFileWriter(filename, true, false); -- create if not exist, do not append but overwrite
	if not fd then return false end;
	bcUtils.writeINItable(fd, content);
	fd:close();
end
--}}}

return bcUtils