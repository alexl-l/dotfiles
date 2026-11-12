hs.alert.defaultStyle.textSize = 12
hs.alert.defaultStyle.padding = 8
hs.alert.defaultStyle.radius = 6

-- Alert management

local function showAlert(message)
  hs.alert.closeAll()
  hs.alert.show(message)
end

-- Mouse Jiggler

local mouseJigglerTimer = nil
local mouseActivityTap = nil
local lastActivity = 0
local lastJiggle = 0
local isJiggling = false

local function jiggleMouse()
  local originalPosition = hs.mouse.absolutePosition()

  local movements = {
    { x = 3, y = 0 },
    { x = 0, y = 3 },
    { x = -3, y = 0 },
    { x = 0, y = -3 },
    { x = 0, y = 0 }
  }

  isJiggling = true

  local index = 1

  local function moveNext()
    local movement = movements[index]

    hs.mouse.setAbsolutePosition({
      x = originalPosition.x + movement.x,
      y = originalPosition.y + movement.y
    })

    index = index + 1

    if index <= #movements then
      hs.timer.doAfter(0.08, moveNext)
    else
      hs.eventtap.keyStroke({}, "capslock", 0)

      hs.timer.doAfter(0.1, function()
        hs.eventtap.keyStroke({}, "capslock", 0)
        isJiggling = false
      end)
    end
  end

  moveNext()
end

local function startMouseJiggler()
  lastActivity = hs.timer.secondsSinceEpoch()
  lastJiggle = 0

  mouseActivityTap = hs.eventtap.new({
    hs.eventtap.event.types.mouseMoved,
    hs.eventtap.event.types.leftMouseDown,
    hs.eventtap.event.types.rightMouseDown,
    hs.eventtap.event.types.otherMouseDown,
    hs.eventtap.event.types.leftMouseDragged,
    hs.eventtap.event.types.rightMouseDragged,
    hs.eventtap.event.types.otherMouseDragged,
    hs.eventtap.event.types.scrollWheel,
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.flagsChanged
  }, function()
    if not isJiggling then
      lastActivity = hs.timer.secondsSinceEpoch()
      lastJiggle = 0
    end

    return false
  end)

  mouseActivityTap:start()

  mouseJigglerTimer = hs.timer.doEvery(1, function()
    local now = hs.timer.secondsSinceEpoch()

    if isJiggling then
      return
    end

    if now - lastActivity >= 10 and
       (lastJiggle == 0 or now - lastJiggle >= 10) then

      lastJiggle = now
      jiggleMouse()
    end
  end)
end

local function stopMouseJiggler()
  if mouseJigglerTimer then
    mouseJigglerTimer:stop()
    mouseJigglerTimer = nil
  end

  if mouseActivityTap then
    mouseActivityTap:stop()
    mouseActivityTap = nil
  end

  isJiggling = false
end

-- Mouse: F12

local function toggleMouseJiggler()
  if mouseJigglerTimer then
    stopMouseJiggler()
    showAlert("Mouse Jiggler OFF")
  else
    startMouseJiggler()
    showAlert("Mouse Jiggler ON")
  end
end

-- Mic: F5

local function toggleMicrophone()
  local mic = hs.audiodevice.defaultInputDevice()

  if not mic then
    showAlert("No microphone found")
    return
  end

  local isMuted = not mic:inputMuted()

  -- Microsoft Teams (works when running in background)
  local teamsApp = hs.application.get("Microsoft Teams")

  if teamsApp then
    hs.eventtap.keyStroke({"cmd", "shift"}, "ñ", 0, teamsApp)
  end

  -- Google Meet (finds the Meet tab even in background)
  local chromeApp = hs.application.get("Google Chrome")

  if chromeApp then
    local script = [[
      tell application "Google Chrome"
        set meetTab to missing value

        repeat with w in windows
          repeat with t in tabs of w
            if (URL of t contains "meet.google.com") then
              set meetTab to t
              exit repeat
            end if
          end repeat

          if meetTab is not missing value then exit repeat
        end repeat

        if meetTab is missing value then return "MEET_NOT_FOUND"

        return execute meetTab javascript "
          (() => {
            const button = Array.from(document.querySelectorAll('button'))
              .find(button => {
                const label = button.getAttribute('aria-label');
                return label && label.toLowerCase().includes('microphone');
              });

            if (!button) return 'BUTTON_NOT_FOUND';

            const isMeetMuted =
              button.getAttribute('aria-label') === 'Turn on microphone';

            if (isMeetMuted !== ]] .. tostring(isMuted) .. [[) {
              button.click();
            }

            return 'OK';
          })()
        "
      end tell
    ]]

    local success, result = hs.osascript.applescript(script)

    if not success then
      print("Google Meet error:", result)
    elseif result ~= "MEET_NOT_FOUND" and result ~= "OK" then
      print("Google Meet response:", result)
    end
  end

  -- Update macOS microphone
  mic:setInputMuted(isMuted)

  showAlert(isMuted and "Microphone Muted" or "Microphone Unmuted")
end

-- Lock EOD: F10

local function lockEndOfDay()
  stopMouseJiggler()
  showAlert("Mouse Jiggler OFF")

  hs.timer.doAfter(2, function()
    hs.eventtap.keyStroke({"ctrl", "cmd"}, "q")
  end)
end

-- Lock: F6

local function lockScreen()
  hs.eventtap.keyStroke({"ctrl", "cmd"}, "q")
end

-- Screenshot: F1

local function screenshot()
  hs.eventtap.keyStroke({"ctrl", "cmd"}, "9")
end

-- Spotify (MTMR play button): 1 tap play/pause, 2 taps next, 3 taps previous

local spotifyTaps = 0
local spotifyTapTimer = nil

local function spotifyTap()
  if not hs.spotify.isRunning() then
    hs.application.launchOrFocus("Spotify")
    return
  end

  spotifyTaps = spotifyTaps + 1

  if spotifyTapTimer then
    spotifyTapTimer:stop()
  end

  spotifyTapTimer = hs.timer.doAfter(0.35, function()
    if spotifyTaps == 1 then
      hs.spotify.playpause()
    elseif spotifyTaps == 2 then
      hs.spotify.next()
    else
      hs.spotify.previous()
    end

    spotifyTaps = 0
  end)
end

hs.urlevent.bind("spotify-tap", spotifyTap)

-- Dialogs: tell MTMR when a dialog, sheet or system prompt is in front, so it steps aside
-- and the Touch Bar shows the app's own buttons (Save, Delete, Allow...)

local systemPromptApps = {
  ["com.apple.SecurityAgent"] = true,
  ["com.apple.UserNotificationCenter"] = true,
  ["com.apple.coreservices.uiagent"] = true,
  ["com.apple.LocalAuthentication.UIAgent"] = true,
  ["com.apple.CoreLocationAgent"] = true,
  ["com.apple.accessibility.universalAccessAuthWarn"] = true
}

-- Only real dialogs count: sheets, modal windows and system dialogs. Plain "AXDialog" windows
-- don't (apps such as Warp keep hidden ones around)
local function isDialog(element)
  return element:attributeValue("AXRole") == "AXSheet" or
    element:attributeValue("AXSubrole") == "AXSystemDialog" or
    element:attributeValue("AXModal") == true
end

local function dialogIsOpen()
  local app = hs.application.frontmostApplication()

  if not app then
    return false
  end

  if systemPromptApps[app:bundleID() or ""] then
    return true
  end

  local appElement = hs.axuielement.applicationElement(app)

  if not appElement then
    return false
  end

  -- Unresponsive apps must not block Hammerspoon
  appElement:setTimeout(0.2)

  -- The focused window is a sheet or alert, or has a sheet attached
  local focusedWindow = appElement:attributeValue("AXFocusedWindow")

  if not focusedWindow then
    return false
  end

  if isDialog(focusedWindow) then
    return true
  end

  for _, child in ipairs(focusedWindow:attributeValue("AXChildren") or {}) do
    if isDialog(child) then
      return true
    end
  end

  -- Focus inside a dialog (e.g. on its default button)
  local element = appElement:attributeValue("AXFocusedUIElement")

  for _ = 1, 12 do
    if not element or element == focusedWindow then
      break
    end

    if isDialog(element) then
      return true
    end

    element = element:attributeValue("AXParent")
  end

  return false
end

-- Event driven, so it costs nothing while idle: checks only when the front app, its focused
-- window or focused element changes, or a window or sheet appears
local dialogOpen = false
local dialogCheck = nil
local dialogObserver = nil

local function postDialogState()
  hs.distributednotifications.post("com.toxblh.mtmr.dialog", nil, { open = dialogOpen and "1" or "0" })
end

local function checkDialog()
  local ok, open = pcall(dialogIsOpen)
  open = ok and open

  if open ~= dialogOpen then
    dialogOpen = open
    postDialogState()
  end
end

local function scheduleDialogCheck()
  if dialogCheck then
    dialogCheck:stop()
  end

  dialogCheck = hs.timer.doAfter(0.15, checkDialog)
end

local function observeApp(app)
  if dialogObserver then
    dialogObserver:stop()
    dialogObserver = nil
  end

  local appElement = app and hs.axuielement.applicationElement(app)

  if appElement then
    dialogObserver = hs.axuielement.observer.new(app:pid())
      :callback(scheduleDialogCheck)

    for _, notification in ipairs({ "AXFocusedWindowChanged", "AXFocusedUIElementChanged", "AXWindowCreated", "AXSheetCreated" }) do
      pcall(function() dialogObserver:addWatcher(appElement, notification) end)
    end

    dialogObserver:start()
  end

  scheduleDialogCheck()
end

dialogAppWatcher = hs.application.watcher.new(function(_, event, app)
  if event == hs.application.watcher.activated then
    observeApp(app)
  elseif event == hs.application.watcher.launched and app and app:bundleID() == "Toxblh.MTMR" then
    -- MTMR (re)started: tell it the current state once it is listening
    hs.timer.doAfter(3, postDialogState)
  end
end)

dialogAppWatcher:start()
observeApp(hs.application.frontmostApplication())

-- Bindings: keyboard shortcuts and hammerspoon:// URLs (used by MTMR)

local actions = {
  { mods = {"fn"}, key = "F12", url = "toggle-jiggler", fn = toggleMouseJiggler },
  { mods = {},     key = "F5",  url = "toggle-mic",     fn = toggleMicrophone },
  { mods = {"fn"}, key = "F10", url = "lock-eod",       fn = lockEndOfDay },
  { mods = {"fn"}, key = "F6",  url = "lock",           fn = lockScreen },
  { mods = {"fn"}, key = "F1",  url = "screenshot",     fn = screenshot }
}

for _, action in ipairs(actions) do
  hs.hotkey.bind(action.mods, action.key, action.fn)
  hs.urlevent.bind(action.url, function() action.fn() end)
end
