local BUFFER_SIZE = 500
local SCRIPT_G = {}
local CLIENTSCRIPTS = {} ---Used to send to joining players etc

function table.size(tab) local l = 0  for _ in pairs(tab) do l = l + 1 end  return l end

function readScripts ( server, client, resource )
	for i,path in ipairs(server) do
		local script,loadFunction = getScript ( path, resource )
		if script then
			if not SCRIPT_G[resource] then
				SCRIPT_G[resource] = {}
				setmetatable(SCRIPT_G[resource], { __index = _G })
			end
			setfenv ( loadFunction, SCRIPT_G[resource] )()
		end
	end
	if SCRIPT_G[resource] and type(SCRIPT_G[resource].onStart) == "function" then
		SCRIPT_G[resource].onStart()
	end
	local scriptInfo = {}
	local resourceName = getResourceName(resource)
	local clientScripts
	for i,path in ipairs(client) do
		--First we send a set of MD5s to client to see if they have the scripts already
		local script = getScript ( path, resource )
		if script then
			local md5 = md5(script) 
			table.insert ( scriptInfo, { path = path, md5 = md5 } ) --Send it as an array so order is mantained.
			CLIENTSCRIPTS[resource] = CLIENTSCRIPTS[resource] or {}
			CLIENTSCRIPTS[resource][path] =  { script = script, md5 = md5, id = i }
			clientScripts = true
		end
	end
	if clientScripts then
		triggerClientEvent ( "requestScriptDownloads", root, scriptInfo, resourceName )
	end 
end

function getScript ( path, resource )
	local script = fileOpen(":" .. getResourceName(resource) .. "/" .. path, true) 
	if not script then return false end
	local scriptString = ""
    while not fileIsEOF(script) do
        scriptString = scriptString..fileRead(script, BUFFER_SIZE)
    end
    fileClose(script) 
	--Attempt to load this script
	local loadFunction, errorMsg = loadstring ( scriptString, path )
	if errorMsg then
		outputDebugString ( "Error: "..getResourceName(resource).."/"..path..": "..errorMsg )
		return false
	end
	return scriptString,loadFunction
end

addEvent ( "requestSendScripts", true )
addEventHandler ( "requestSendScripts", root,
	function ( requiredFiles, resourceName )
		local resource = getResourceFromName(resourceName)
		if resource then
			for i,path in pairs(requiredFiles) do
				local data = CLIENTSCRIPTS[resource][path]
				if data then
					if #data.script + #resourceName <= 65535 then
						triggerClientEvent ( client, "downloadScript", client, data.script, i, resourceName )
					else
						outputDebugString ( "Error: "..resourceName.."/"..path..": This script is too large to download" )
					end
				end
			end
		end
	end
)

addEventHandler ( "onPlayerJoin", root,
	function()
		for resource,data in pairs(CLIENTSCRIPTS) do
			local scriptInfo = {}
			local clientScripts
			for path,info in pairs(data) do
				scriptInfo[info.id] = { path = path, md5 = info.md5 }
				clientScripts = true
			end
			local resourceName = getResourceName(resource)
			if clientScripts then
				triggerClientEvent ( "requestScriptDownloads", root, scriptInfo, resourceName )
			end 
		end
	end
)

addEventHandler ( "onResourceStop", root,
	function(resource)
		if SCRIPT_G[resource] then
			SCRIPT_G[resource] = nil --Unload our script
		end
	end
)