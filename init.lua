-- Table to hold the current layout snapshot
local currentLayout = {}

lastApplication = hs.application.frontmostApplication()

function saveAndFocusHammerspoon()
	lastApplication = hs.application.frontmostApplication()
	hs.application.get("Hammerspoon"):activate()
end

function goBackToSavedWindow()
	if lastApplication then
		lastApplication:activate()
	end
end

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
	print("debugAllWindows()")
	local windows = hs.window.allWindows()
	local res = ""
	for _, win in ipairs(windows) do
		app = win:application():name()
		title = win:title()

		local str = '{ { "" }, { { app = "' .. app .. '", title = "' .. title .. '"} } }'
		print(str)
		res = res .. "\n" .. str

		-- For even more detail, including methods and properties not directly accessible:
		-- print(hs.inspect(getmetatable(win)))
	end
	hs.pasteboard.writeObjects(res)
end
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "D", debugAllWindows)

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

function index(arrOrStr, index)
	if type(arrOrStr) == "string" then
		if index > #arrOrStr then
			return nil
		end
		return arrOrStr:sub(index, index)
	elseif type(arrOrStr) == "table" then
		return arrOrStr[index]
	end
end

function compareIndexable(a, b)
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if index(a, i) ~= index(b, i) then
			return false
		end
	end
	return true
end -----------------------------------------
--  ___  ___ _ __(_) __ _| (_)_______  --
-- / __|/ _ \ '__| |/ _` | | |_  / _ \ --
-- \__ \  __/ |  | | (_| | | |/ /  __/ --
-- |___/\___|_|  |_|\__,_|_|_/___\___| --
-----------------------------------------

function isSequentialTable(t)
	local i = 0
	for _ in pairs(t) do
		i = i + 1
		if t[i] == nil then
			return false
		end
	end
	return true
end

function serializeTable(val, name, depth)
	print("serializeTable name:", name, ",depth:", depth)
	depth = depth or 0
	local temp = string.rep(" ", depth)
	if name then
		temp = temp .. name .. " = "
	end

	if type(val) == "table" then
		if isSequentialTable(val) then
			-- Treat as an array
			temp = temp .. "{" .. "\n"
			for _, v in ipairs(val) do
				temp = temp .. serializeTable(v, nil, depth + 1) .. "," .. "\n"
			end
		else
			-- Treat as a map
			temp = temp .. "{" .. "\n"
			for k, v in pairs(val) do
				temp = temp .. serializeTable(v, k, depth + 1) .. "," .. "\n"
			end
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
	-- file:write("return " .. serializeTable(t))
	file:write("return " .. hs.inspect(t))
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

function findExistingShortcut(code, table)
	for index, match in ipairs(table) do
		local key = match[1]
		local val = match[2]
		if compareIndexable(key, code) then
			return index
		end
	end
	return nil
end

function findWindowInExistingShortcuts(win)
	local res = {}
	local title = win:title()
	local app = win:application():title()
	for outerIndex, match in ipairs(matches) do
		local windows = match[2]
		for innerIndex, matchWin in ipairs(windows) do
			if app == matchWin.app and title == matchWin.title then
				table.insert(res, { outerIndex, innerIndex })
			end
		end
	end
	return res
end

function removeExtraText(str)
	local res = str
	res = string.gsub(res, "%- Audio playing %-", "-")
	return res
end

--------------------------------------------
--   ___ ___  _ __ | |_ _____  _| |_ ___  --
--  / __/ _ \| '_ \| __/ _ \ \/ / __/ __| --
-- | (_| (_) | | | | ||  __/>  <| |_\__ \ --
--  \___\___/|_| |_|\__\___/_/\_\\__|___/ --
--------------------------------------------

matches = loadTable("matches.lua")
table.insert(matches, { { "s", "p" }, { { app = "Spotify", title = "Spotify Premium" } } })

function handleAddShortcut()
	local win = hs.window.frontmostWindow()
	local app = win:application():title()
	local title = removeExtraText(win:title())

	local res, newCode = hs.dialog.textPrompt(app .. " >> " .. title, "input code", "", "Add", "Cancel")
	if res == "Cancel" then
		return
	end

	local existingFunctionShortcut = findExistingShortcut(newCode, matchFunctions)
	if existingFunctionShortcut then
		hs.dialog.blockAlert("That shortcut already belongs to a function.", "")
		return
	end

	local existingShortcut = findExistingShortcut(newCode, matches)
	if existingShortcut == nil then
		addShortcut(app, title, newCode)
		saveTable(matches, "matches.lua")
	else
		local res2, choice = hs.dialog.textPrompt(
			"That shortcut already exists: " .. hs.inspect(matches[existingShortcut][2]),
			"[A]ppend, [R]eplace, or cancel",
			"",
			"OK",
			"Cancel"
		)
		if res2 == "Cancel" then
			return
		elseif string.lower(choice) == "a" then
			appendShortcut(app, title, existingShortcut)
		elseif string.lower(choice) == "r" then
			replaceShortcut(app, title, existingShortcut)
		end
	end
end

function inspectWindow(win)
	local id = win:id() or "NOID"
	local title = win:title()
	local app = win:application():name()
	local frame = win:frame()
	local screen = win:screen():name()

	-- Prepare the information string
	local info = string.format(
		"Window ID: %s\nTitle: %s\nApplication: %s\nFrame: %s\nScreen: %s",
		id,
		title,
		app,
		hs.inspect(frame),
		screen
	)
	return info
end

function handleShowUnsetWindows()
	local windows = hs.window.allWindows()
	local unsetWindows = {}
	for _, win in ipairs(windows) do
		local matches = findWindowInExistingShortcuts(win)
		if #matches == 0 then
			table.insert(unsetWindows, win)
		end
	end
	table.sort(unsetWindows, function(a, b)
		return (a:application():title() .. a:title()) < (b:application():title() .. b:title())
	end)
	local winStr = ""
	for index, win in ipairs(unsetWindows) do
		winStr = winStr .. "\n" .. index .. ". " .. win:application():title() .. " -> " .. win:title()
	end

	saveAndFocusHammerspoon()
	local res, userInput = hs.dialog.textPrompt("", winStr, "", "OK", "Cancel")
	goBackToSavedWindow()
	if res == "Cancel" then
		return
	end

	local command = string.match(userInput, "%a")
	local number = string.match(userInput, "%d+")
	if number == nil then
		return
	end
	number = tonumber(number)
	if number > #unsetWindows or number <= 0 then
		return
	end
	local targetWin = { app = unsetWindows[number]:application():title(), title = unsetWindows[number]:title() }
	goToWindow(targetWin)
end

function handleShowSetWindows()
	local windows = hs.window.allWindows()
	local unsetWindows = {}
	for _, win in ipairs(windows) do
		local matchIndexes = findWindowInExistingShortcuts(win)
		if #matchIndexes >= 1 then
			table.insert(unsetWindows, { indexes = matchIndexes, win = win })
		end
	end
	table.sort(unsetWindows, function(a, b)
		return (a.win:application():title() .. a.win:title()) < (b.win:application():title() .. b.win:title())
	end)
	local winStr = ""
	for index, win in ipairs(unsetWindows) do
		local i = win.indexes
		local x = hs.inspect(matches[i[1][1]][1])
		winStr = winStr .. "\n" .. x .. ". " .. win.win:application():title() .. " -> " .. win.win:title()
	end

	saveAndFocusHammerspoon()
	local res, userInput = hs.dialog.textPrompt("", winStr, "", "OK", "Cancel")
	goBackToSavedWindow()
	if res == "Cancel" then
		return
	end

	-- local command = string.match(userInput, "%a")
	-- local number = string.match(userInput, "%d+")
	-- if number == nil then
	-- 	return
	-- end
	-- number = tonumber(number)
	-- if number > #unsetWindows or number <= 0 then
	-- 	return
	-- end
	-- local targetWin = { app = unsetWindows[number].win:application():title(), title = unsetWindows[number].win:title() }
	-- goToWindow(targetWin)
end

matchFunctions = {
	{
		{ "space", "a" },
		handleAddShortcut, -- needs to match codes after, or get another way of inputting code
	},
	{ { "space", "r" }, hs.reload },
	{ { "space", "c" }, hs.console.clearConsole },
	{ { "space", "u" }, handleShowUnsetWindows },
	{ { "space", "w" }, handleShowSetWindows },
}

function addShortcut(app, title, code)
	local newWindow = { app = app, title = title }
	table.insert(matches, { code, { newWindow } })
	print("matches with new code hopefully added:", hs.inspect(matches))
end

function appendShortcut(app, title, index)
	print("appendShortcut")
	local newWindow = { app = app, title = title }
	table.insert(matches[index][2], newWindow)
end

function replaceShortcut(app, title, index)
	print("replaceShortcut")
	local newWindow = { app = app, title = title }
	matches[index][2] = { newWindow }
end

function handleCapturedSequence(sequence)
	print("Captured sequence:", hs.inspect(sequence))

	for _, match in ipairs(matches) do
		local keys = match[1]
		local wins = match[2]
		if compareIndexable(sequence, keys) then
			for _, win in ipairs(wins) do
				goToWindow(win)
			end
		end
	end

	for _, match in ipairs(matchFunctions) do
		local keys = match[1]
		local func = match[2]
		if compareIndexable(sequence, keys) then
			func()
		end
	end
end

function goToWindow(win)
	-- local orderedWindows = hs.window.orderedWindows()
	-- if _goToWindow(win.app, win.title, orderedWindows) then
	-- 	return
	-- end
	local allWindows = hs.window.allWindows()
	_goToWindow(win.app, removeExtraText(win.title), allWindows)
end

function _goToWindow(app, title, windows)
	print("_goToWindow title: ", title)
	for _, win in ipairs(windows) do
		if removeExtraText(win:title()) == title and win:application():title() == app then
			win:unminimize()
			win:focus()
			return true
		end
	end

	for _, win in ipairs(windows) do
		if win:application():title() == app then
			win:unminimize()
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
	print(str)
end

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "W", copyCurrentWindow)

local capturedKeys = {}
local isRightOptionPressed = false
local ignoreBecauseOfModifier = false

local function handleKeyEvent(event)
	local currentModifiers = hs.eventtap.checkKeyboardModifiers()
	-- print("  currentModifiers:", mapToString(currentModifiers))
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
		-- print("quick ignore")
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
