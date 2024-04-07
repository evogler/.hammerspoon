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
		if counter == 3 then
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
	local windows = hs.window.orderedWindows()
	for _, win in ipairs(windows) do
		-- Capture and print detailed window information
		local winDetails = {
			id = win:id(),
			app = win:application():name(),
			title = win:title(),
			frame = win:frame(),
			minimized = win:isMinimized(),
			isVisible = win:isVisible(),
			isStandard = win:isStandard(),
			role = win:role(),
			subrole = win:subrole(),
		}

		-- Using hs.inspect to print the detailed information
		print(hs.inspect(winDetails))

		-- For even more detail, including methods and properties not directly accessible:
		-- print(hs.inspect(getmetatable(win)))
	end
end

local capturedKeys = {}
local isRightOptionPressed = false
local otherModifiersPressed = false

-- other modifiers: 56, 59, 63, 58, 55, 54, 60 (56 & 60 are shift)

local function handleKeyEvent(event)
	local keyCode = event:getKeyCode()
	local eventType = event:getType()
	local flags = event:getFlags()
	print(keyCode, eventType, flags)

	-- Check for other modifiers when right option is pressed or during sequence capture
	otherModifiersPressed = not (flags.rightalt == true and next(flags) == "rightalt") -- `next` checks if rightalt is the only key in flags

	if eventType == hs.eventtap.event.types.flagsChanged and keyCode == 61 then
		if not isRightOptionPressed then
			isRightOptionPressed = true
			capturedKeys = {}
			-- Check for other modifiers upon initial press
			if otherModifiersPressed then
				-- Ignore or reset if other modifiers are pressed
				isRightOptionPressed = false
				capturedKeys = {}
				return false
			end
		else
			-- Right option key was released
			isRightOptionPressed = false
			if not otherModifiersPressed then
				-- Process the captured sequence if no other modifiers were involved
				print("Captured sequence:", hs.inspect(capturedKeys))
				-- Optionally, display an alert here
				hs.alert.show("Captured sequence: " .. table.concat(capturedKeys, ", "))
			end
			capturedKeys = {} -- Clear captured keys after processing
		end
	elseif isRightOptionPressed and eventType == hs.eventtap.event.types.keyDown and not otherModifiersPressed then
		-- Capture keys if only right option is pressed
		table.insert(capturedKeys, keyCode)
	end
end

-- Create and start the event tap
local eventTap =
	hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.flagsChanged }, handleKeyEvent)
eventTap:start()
