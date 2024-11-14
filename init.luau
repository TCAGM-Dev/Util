--!strict

local Util = {}

function Util.forPlayers(callback: (Player) -> nil)
	game.Players.PlayerAdded:Connect(callback)
	for _, player in game.Players:GetPlayers() do
		task.spawn(callback, player)
	end
end

function Util.forCharacters(callback: (Model, Player) -> nil)
	Util.forPlayers(function(player)
		local characterconnection = player.CharacterAdded:Connect(function(character)
			callback(character, player)
		end)
		player.Destroying:Once(function()
			characterconnection:Disconnect()
		end)
	end)
	for _, player in game.Players:GetPlayers() do
		local character = player.Character
		if character then
			task.spawn(callback, character, player)
		end
	end
end

local playerjointimes = {}
Util.forPlayers(function(plr)
	playerjointimes[plr] = time()
end)
game.Players.PlayerRemoving:Connect(function(plr)
	playerjointimes[plr] = nil
end)
function Util.getPlayerSessionLength(plr: Player): number
	return time() - playerjointimes[plr]
end

function Util.shift<K>(t: {K}): K?
	return table.remove(t, 1)
end

function Util.merge<K>(t1: {[string]: K}, t2: {[string]: K}): {[string]: K}
	local result = table.clone(t1)
	for key, value in pairs(t2) do
		result[key] = value
	end
	return result
end

function Util.match<K>(t: {K}, predicate: (K) -> boolean): K?
	for _, v in ipairs(t) do
		if predicate(v) == true then
			return v
		end
	end
	return nil
end

function Util.find<K>(t: {K}, predicate: (K) -> boolean): number
	for i, v in ipairs(t) do
		if predicate(v) == true then
			return i
		end
	end
	return -1
end

function Util.some<K>(t: {K}, predicate: (K) -> boolean): boolean
	for _, v in ipairs(t) do
		if predicate(v) == true then
			return true
		end
	end
	return false
end

function Util.all<K>(t: {K}, predicate: (K) -> boolean): boolean
	for _, v in ipairs(t) do
		if predicate(v) == false then
			return false
		end
	end
	return true
end

function Util.contains<K>(t: {K}, needle: K): boolean
	return Util.some(t, function(v)
		return v == needle
	end)
end

function Util.insertAware<K>(t: {K}, item: K): boolean
	if Util.contains(t, item) then
		return false
	else
		table.insert(t, item)
		return true
	end
end

function Util.startswith(haystack: string, needle: string): boolean
	return string.sub(haystack, 1, string.len(needle)) == needle
end

function Util.choose<K>(t: {K}): K
	return t[math.random(#t)]
end

function Util.filter<K>(t: {K}, predicate: (K) -> boolean): {K}
	local r = {}
	for _, v in ipairs(t) do
		if predicate(v) == true then
			table.insert(r, v)
		end
	end
	return r
end

function Util.map<K, T>(t: {K}, transform: (K) -> T): {T}
	local r = {}
	for i, v in ipairs(t) do
		r[i] = transform(v)
	end
	return r
end

function Util.objectKeys<T>(t: {[T]: any}): {T}
	local result = {}
	for key, _ in pairs(t) do
		table.insert(result, key)
	end
	return result
end
function Util.objectValues<T>(t: {[any]: T}): {T}
	local result = {}
	for _, value in pairs(t) do
		table.insert(result, value)
	end
	return result
end

function Util.every(t: number, f: (delta: number) -> nil): thread
	local c: thread = coroutine.create(function()
		while true do
			f(task.wait(t))
		end
	end)
	coroutine.resume(c)
	return c
end

function Util.applyProperties(instance: Instance, properties: {[string]: any}): Instance
	for key, value in pairs(properties) do
		if key ~= "Parent" then -- Skip the Parent property in the loop to do it later and insure it is set last
			instance[key] = value
		end
	end
	if properties.Parent then
		instance.Parent = properties.Parent
	end
	return instance
end
function Util.createInstance(class: string | Instance, properties: {[string]: any}?, children: {[string | number]: Instance}?): Instance
	local instance = if typeof(class) == "string" then Instance.new(class) else class:Clone()
	
	if properties then
		Util.applyProperties(instance, properties)
	end

	if children then
		for key, child in pairs(children) do
			if typeof(key) == "string" then
				child.Name = key
			end
			child.Parent = instance
		end
	end

	return instance
end

function Util.formatTimeLength(t: number): string
	local seconds = math.floor(t) % 60
	local minutes = math.floor(t / 60) % 60
	local hours = math.floor(t / 3600) % 24
	local days = math.floor(t / 86400) % 365
	local years = math.floor(t / 31536000)

	if years > 0 then
		return `{years}y{days}d {hours}h {minutes}m {seconds}s`
	elseif days > 0 then
		return `{days}d {hours}h {minutes}m {seconds}s`
	elseif hours > 0 then
		return `{hours}h {minutes}m {seconds}s`
	elseif minutes > 0 then
		return `{minutes}m {seconds}s`
	else
		return `{seconds}s`
	end
end

return Util