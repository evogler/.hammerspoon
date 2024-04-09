-- Table to hold the current layout snapshot
local currentLayout = {}

function snapshotCurrentLayout()
	local windows = hs.window.orderedWindows()
	local layout = {}
	local counter = 0
	for _, win in ipairs(windows) do
		if win:isStandard() and win:isVisible() and not win:isMinimized() then
			local winSnapshot = {
				id = win:id(),
				app = win:application():name(),
				title = win:title(),
				frame = win:frame(),
			}
			-- Add window snapshot to the layout table
			table.insert(layout, winSnapshot)

			-- Print window snapshot for debugging
			print(hs.inspect(winSnapshot))
			counter = counter + 1
		end
		if counter == 2 then
			break
		end
	end
	currentLayout = layout
	hs.alert.show("Window layout saved")
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do
		count = count + 1
	end
	return count
end

function restoreLayout(layout)
	local allWindows = hs.window.allWindows()
	-- for _, win in ipairs(allWindows) do
	-- 	if win:isStandard() then
	-- 		win:minimize()
	-- 	end
	-- end
	for i = #layout, 1, -1 do
		local winInfo = layout[i]
		local matchedWindows = hs.fnutils.filter(hs.window.allWindows(), function(win)
			return win:application():name() == winInfo.app and win:title() == winInfo.title
		end)
		for _, win in ipairs(matchedWindows) do
			if win:title() == winInfo.title then
				if win:isMinimized() then
					win:unminimize()
				end
				win:focus()
				hs.timer.doAfter(0.1, function()
					win:setFrame(winInfo.frame)
				end)
				break
			end
		end
	end
	hs.alert.show("Window layout restored")
end

-- Set up hotkeys
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "S", snapshotCurrentLayout)
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "R", function()
	restoreLayout(currentLayout)
end)

function debugAllWindows()
	local windows = hs.window.allWindows()
	for _, win in ipairs(windows) do
		app = win:application():name()
		title = win:title()

		local str = '{ { "" }, { { app = "' .. app .. '", title = "' .. title .. '"} } }'
		print(str)

		-- For even more detail, including methods and properties not directly accessible:
		-- print(hs.inspect(getmetatable(win)))
	end
end

function toBinary(num)
	local bin = "" -- Create an empty string to store the binary form
	local rem -- Declare a variable to store the remainder

	-- This loop iterates over the number, dividing it by 2 and storing the remainder each time
	-- It stops when the number has been divided down to 0
	while num > 0 do
		rem = num % 2 -- Get the remainder of the division
		bin = rem .. bin -- Add the remainder to the string (in front, since we're iterating backwards)
		num = math.floor(num / 2) -- Divide the number by 2
	end

	return bin -- Return the string
end

function mapToString(arr)
	local res = ""
	for key, _ in pairs(arr) do
		res = res .. " " .. key
	end
	return res
end

function mapContains(map, val)
	for key, _ in pairs(map) do
		if key == val then
			return true
		end
	end
	return false
end

function compareArrays(arr1, arr2)
	if #arr1 ~= #arr2 then
		return false
	end
	for index, val in ipairs(arr1) do
		if val ~= arr2[index] then
			return false
		end
	end
	return true
end

-----------------------------------------
--  ___  ___ _ __(_) __ _| (_)_______  --
-- / __|/ _ \ '__| |/ _` | | |_  / _ \ --
-- \__ \  __/ |  | | (_| | | |/ /  __/ --
-- |___/\___|_|  |_|\__,_|_|_/___\___| --
-----------------------------------------

function serializeTable(val, name, depth)
	skipnewlines = false
	depth = depth or 0
	local temp = string.rep(" ", depth)
	if name then
		temp = temp .. name .. " = "
	end

	if type(val) == "table" then
		temp = temp .. "{" .. "\n"
		for k, v in pairs(val) do
			temp = temp .. serializeTable(v, k, depth + 1) .. "," .. "\n"
		end
		temp = temp .. string.rep(" ", depth) .. "}"
	elseif type(val) == "number" then
		temp = temp .. tostring(val)
	elseif type(val) == "string" then
		temp = temp .. string.format("%q", val)
	end

	return temp
end

function saveTable(t, filename)
	local file = io.open(filename, "w")
	file:write("return " .. serializeTable(t))
	file:close()
end

function loadTable(filename)
	local f, err = loadfile(filename)
	if f then
		return f()
	else
		error(err)
	end
end

--------------------------------------------
--   ___ ___  _ __ | |_ _____  _| |_ ___  --
--  / __/ _ \| '_ \| __/ _ \ \/ / __/ __| --
-- | (_| (_) | | | | ||  __/>  <| |_\__ \ --
--  \___\___/|_| |_|\__\___/_/\_\\__|___/ --
--------------------------------------------

matches = loadTable("matches.lua")
table.insert(matches, { { "s", "p" }, { { app = "Spotify", title = "Spotify Premium" } } })
table.insert(matches, {
	{ "space", "a" }, -- needs to match codes after, or get another way of inputting code
	function()
		-- get current window
		local win = hs.window.frontmostWindow()
		local app = win:application():title()
		local title = win:title()
		-- input user code
		local res, userText = hs.dialog.textPrompt(app .. " >> " .. title, "")
		hs.alert(userText)
		hs.dialog.blockAlert(
			"test\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\ntest\n",
			""
		)

		-- hs.dialog.blockAlert(userText, "")
		-- check if code is currently in use and if so, ask if user wants to overwrite (if not, abort)
		-- add the setting. remove the old one if it exists
		-- write to matches.lua
		-- reload hammerspoon
	end,
})

function handleCapturedSequence(sequence)
	print("Captured sequence:", hs.inspect(sequence))
	for _, match in ipairs(matches) do
		local keys = match[1]
		local winsOrFunc = match[2]
		if compareArrays(sequence, keys) then
			if type(winsOrFunc) == "table" then
				for _, win in ipairs(winsOrFunc) do
					goToWindow(win)
				end
			else
				winsOrFunc()
			end
			return
		end
	end
end

function goToWindow(win)
	local orderedWindows = hs.window.orderedWindows()
	if _goToWindow(win.app, win.title, orderedWindows) then
		return
	end
	local allWindows = hs.window.allWindows()
	_goToWindow(win.app, win.title, allWindows)
end

function _goToWindow(app, title, windows)
	-- title =
	for _, win in ipairs(windows) do
		if win:title() == title and win:application():title() == app then
			win:focus()
			return true
		end
	end
	return false
end

function copyCurrentWindow()
	local win = hs.window.focusedWindow()
	local app = win:application():title()
	local title = win:title()
	local str = '{ app = "' .. app .. '", title = "' .. title .. '"}'
	hs.pasteboard.writeObjects(str)
end

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "W", copyCurrentWindow)

local capturedKeys = {}
local isRightOptionPressed = false
local ignoreBecauseOfModifier = false

local function handleKeyEvent(event)
	local currentModifiers = hs.eventtap.checkKeyboardModifiers()
	print("  currentModifiers:", mapToString(currentModifiers))
	if
		mapContains(currentModifiers, "cmd")
		or (mapContains(currentModifiers, "alt") and not isRightOptionPressed)
		or mapContains(currentModifiers, "ctrl")
		or mapContains(currentModifiers, "shift")
	then
		print("  already being modified")
		return false
	end

	local keyCode = event:getKeyCode()
	if keyCode ~= 61 and isRightOptionPressed == false then
		print("quick ignore")
		return false
	end

	local otherModifierKeyCodes = { 56, 59, 63, 58, 55, 54, 60 }

	if hs.fnutils.contains(otherModifierKeyCodes, keyCode) then
		print("setting ignore to true")
		ignoreBecauseOfModifier = true
		return false
	end

	if keyCode == 61 then -- Right option key
		if not currentModifiers.alt then
			isRightOptionPressed = true
			capturedKeys = {}
			if ignoreBecauseOfModifier then
				isRightOptionPressed = false
				ignoreBecauseOfModifier = false
				capturedKeys = {}
			end
		else
			isRightOptionPressed = false
			if not ignoreBecauseOfModifier and #capturedKeys > 0 then
				handleCapturedSequence(capturedKeys)
			end
			capturedKeys = {}
			ignoreBecauseOfModifier = false
		end
		return false
	elseif isRightOptionPressed and not ignoreBecauseOfModifier then
		table.insert(capturedKeys, hs.keycodes.map[keyCode])
		return true
	end
end

-- Create and start the event tap
eventTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged }, handleKeyEvent)
-- hs.eventtap.new({ hs.eventtap.event.types.flagsChanges }, handleKeyEvent)
eventTap:start()
