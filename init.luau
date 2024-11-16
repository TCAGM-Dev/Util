--!strict

local Util = {}

-- Executes the given callback for every player, regardless of if they are in game already
function Util.forPlayers(callback: (Player) -> nil)
	game.Players.PlayerAdded:Connect(callback)
	for _, player in game.Players:GetPlayers() do
		task.spawn(callback, player)
	end
end

-- Executes the given callback for every player's character that spawns
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

-- Returns the given player's current session's length
function Util.getPlayerSessionLength(plr: Player): number
	return time() - playerjointimes[plr]
end

-- Removes and returns the first item in a list
function Util.shift<K>(t: {K}): K?
	return table.remove(t, 1)
end

-- Concatenates multiple lists and returns the result
function Util.merge<K>(t1: {[string]: K}, t2: {[string]: K}): {[string]: K}
	local result = table.clone(t1)
	for key, value in pairs(t2) do
		result[key] = value
	end
	return result
end

-- Returns the first item in a list that matches the specified predicate
function Util.match<K>(t: {K}, predicate: (K) -> boolean): K?
	for _, v in ipairs(t) do
		if predicate(v) == true then
			return v
		end
	end
	return nil
end

-- Returns the index of the first item in a list that matches the specified predicate
function Util.find<K>(t: {K}, predicate: (K) -> boolean): number
	for i, v in ipairs(t) do
		if predicate(v) == true then
			return i
		end
	end
	return -1
end

-- Returns true if any items in the list match the predicate
function Util.some<K>(t: {K}, predicate: (K) -> boolean): boolean
	for _, v in ipairs(t) do
		if predicate(v) == true then
			return true
		end
	end
	return false
end

-- Returns true if all items in the list match the predicate
function Util.all<K>(t: {K}, predicate: (K) -> boolean): boolean
	for _, v in ipairs(t) do
		if predicate(v) == false then
			return false
		end
	end
	return true
end

-- Returns whether an item is present in a list
function Util.contains<K>(t: {K}, needle: K): boolean
	return Util.some(t, function(v)
		return v == needle
	end)
end

-- Inserts an item at the end of a list <i>if it doesn't exist yet</i>
function Util.insertAware<K>(t: {K}, item: K): boolean
	if Util.contains(t, item) then
		return false
	else
		table.insert(t, item)
		return true
	end
end

-- Returns if the haystack string starts with the needle string
function Util.startswith(haystack: string, needle: string): boolean
	return string.sub(haystack, 1, string.len(needle)) == needle
end

-- Returns a random item from the list
function Util.choose<K>(t: {K}): K
	return t[math.random(#t)]
end

-- Returns a random item from a list, respecting it's weight
function Util.weightedRandom<K>(t: {{Value: K, Weight: number}}): {Value: K, Weight: number}
	local weightSum = 0
	for _, item in t do
		weightSum += item.Weight
	end

	local random = math.random() * weightSum

	for _, item in t do
		if random < item.Weight then
			return item
		end
		random -= item.Weight
	end
end

-- Returns the list but filtered containing only the items that match the given predicate
function Util.filter<K>(t: {K}, predicate: (K) -> boolean): {K}
	local r = {}
	for _, v in ipairs(t) do
		if predicate(v) == true then
			table.insert(r, v)
		end
	end
	return r
end

-- Maps the items in a list to another item with the given transform function
function Util.map<K, T>(t: {K}, transform: (K) -> T): {T}
	local r = {}
	for i, v in ipairs(t) do
		r[i] = transform(v)
	end
	return r
end

-- Returns a list of keys present in a dictionary
function Util.objectKeys<T>(t: {[T]: any}): {T}
	local result = {}
	for key, _ in pairs(t) do
		table.insert(result, key)
	end
	return result
end

-- Returns a list of values present in a dictionary
function Util.objectValues<T>(t: {[any]: T}): {T}
	local result = {}
	for _, value in pairs(t) do
		table.insert(result, value)
	end
	return result
end

-- Executes a function every <code>t</code> seconds
function Util.every(t: number, f: (delta: number) -> nil): thread
	local c: thread = coroutine.create(function()
		while true do
			f(task.wait(t))
		end
	end)
	coroutine.resume(c)
	return c
end

-- Applies a properties table to an instance
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

type Children = Instance | {Children} | {[string]: Instance}

-- Applies a children table to an instance
function Util.applyChildren(instance: Instance, children: Children): Instance
	if typeof(children) == "Instance" then
		children.Parent = instance
	elseif typeof(children) == "table" then
		for key, child in pairs(children) do
			if typeof(child) == "table" then
				Util.applyChildren(instance, child)
			elseif typeof(key) == "string" then
				child.Name = key
			end
			child.Parent = instance
		end
	end
	return instance
end

-- Roact-style instance creation; Makes an instance or a clone of an instance and applies the given properties and children tables to it
function Util.createInstance(class: string | Instance, properties: {[string]: any}?, children: Children?): Instance
	local instance = if typeof(class) == "string" then Instance.new(class) else class:Clone()
	
	if properties then
		Util.applyProperties(instance, properties)
	end

	if children then
		Util.applyChildren(instance, children)
	end

	return instance
end

-- Formats the given time in seconds as a timespan; 2y46d 18h 54m 2s
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

-- Returns a debounced function; Only executes <code>f</code> when it hasn't been executed for <code>time</code> seconds
-- It recieves the arguments of the latest execution
function Util.debounce<K...>(f: (K...) -> nil, time: number): (K...) -> nil
	local currentThread: thread?
	return function(...)
		if currentThread then
			coroutine.close(currentThread)
			currentThread = nil
		end
		currentThread = task.delay(time, f, ...)
	end
end

-- Returns a throttled function; Ensures that <code>f</code> is never executed more often than every <code>time</code> seconds
function Util.throttle<K...>(f: (K...) -> nil, time: number): (K...) -> nil
	local cooldown = false
	return function(...)
		if cooldown then return end
		cooldown = true
		task.spawn(f, ...)
		task.delay(time, function()
			cooldown = false
		end)
	end
end

return Util