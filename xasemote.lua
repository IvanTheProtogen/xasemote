local xasemote = {}

function xasemote.hash(input)
	input = tostring(input)
	local x = 0
	for i=1,#input do
		x = x + input:byte(i)
	end
	return ('d'):pack(math.sin(math.sin(x)*x)*x)
end
function xasemote.encrypt(data,key)
	data,key = tostring(data),tostring(key)
	local datab,keyb = {},{}
	for sym in data:gmatch(".") do
		table.insert(datab,sym)
	end
	for sym in key:gmatch(".") do
		table.insert(keyb,sym)
	end
	for i=1,#datab do
		datab[i] = string.char((datab[i]:byte()+keyb[(i % #keyb)+1]:byte())%256)
	end
	return table.concat(datab)
end
function xasemote.decrypt(data,key)
	data,key = tostring(data),tostring(key)
	local datab,keyb = {},{}
	for sym in data:gmatch(".") do
		table.insert(datab,sym)
	end
	for sym in key:gmatch(".") do
		table.insert(keyb,sym)
	end
	for i=1,#datab do
		datab[i] = string.char((datab[i]:byte()-keyb[(i % #keyb)+1]:byte())%256)
	end
	return table.concat(datab)
end


local players = game:GetService("Players")
local isserver = game:GetService("RunService"):IsServer()

function xasemote.genkey(plr)
	local key = 0
	for _,str in {
		game.JobId,
		plr.Name,
		plr.DisplayName,
		('d'):pack(game.PlaceId),
		('d'):pack(plr.AccountAge),
		('d'):pack(plr.UserId),
		tostring(game.PlaceId),
		tostring(plr.AccountAge),
		tostring(plr.UserId)
	} do 
		for i=1,#str do 
			key = key + str:byte(i)
		end
	end 
	return xasemote.hash(key)
end 

function xasemote.pack(key,data,...)
	assert(#({...})==0, 'argument amount')
	if key or isserver then else 
		key = key or players.LocalPlayer
	end 
	if typeof(key)=='Instance' then 
		assert(key.ClassName=='Player','player type')
		key = xasemote.genkey(key)
	else assert(type(key)=='string','key type') end 
	local hashA = xasemote.hash(data)
	local hashC = xasemote.hash(key)
	data = xasemote.encrypt(data,key)
	local hashB = xasemote.hash(data)
	local unix = ('d'):pack(tick())
	local hashX = xasemote.hash(unix)
	unix = xasemote.encrypt(unix,key)
	local hashY = xasemote.hash(unix)
	return {data,hashA,hashB,hashC,unix,hashX,hashY}
end 

function xasemote.unpack(key,data,acceptedUnixL,acceptedUnixR,...)
	assert(#({...})==0, 'argument amount')
	assert(type(data)=='table', 'packet type')
	assert(getmetatable(data)==nil, 'metatable hook attempt')
	assert(data[1] and data[2] and data[3] and data[4] and data[5] and data[6] and data[7], 'packet structure')
	assert(#data==7, 'packet size')
	if key or isserver then else 
		key = key or players.LocalPlayer
	end 
	if typeof(key)=='Instance' then 
		assert(key.ClassName=='Player','player type')
		key = xasemote.genkey(key)
	else assert(type(key)=='string','key type') end 
	assert(type(data[1])=='string','data type')
	assert(type(data[2])=='string','decrypt hash type')
	assert(type(data[3])=='string','encrypt hash type')
	assert(type(data[4])=='string','key hash type')
	local checkC = xasemote.hash(key)
	assert(checkC==data[4],'key check')
	local checkB = xasemote.hash(data[1])
	assert(checkB==data[3],'encrypt check')
	local new = xasemote.decrypt(data[1],key)
	local checkA = xasemote.hash(new)
	assert(checkA==data[2],'decrypt check')
	assert(type(data[5])=='string','unix type')
	assert(type(data[6])=='string','unix decrypt type')
	assert(type(data[7])=='string','unix encrypt type')
	acceptedUnixL = (acceptedUnixL and tonumber(acceptedUnixL)) or 60 
	acceptedUnixR = (acceptedUnixR and tonumber(acceptedUnixR)) or 120
	local checkY = xasemote.hash(data[5])
	assert(checkY==data[7],'unix encrypt check')
	local dunix = xasemote.decrypt(data[5],key)
	local checkX = xasemote.hash(dunix)
	assert(checkX==data[6],'unix decrypt check')
	dunix = ('d'):unpack(dunix)
	local realunix = tick()
	assert((realunix-acceptedUnixL <= dunix) and (dunix <= realunix+acceptedUnixR), 'unix check')
	return new 
end 

return xasemote
