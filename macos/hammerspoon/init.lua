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

hs.hotkey.bind({"fn"}, "F12", function()
  if mouseJigglerTimer then
    stopMouseJiggler()
    showAlert("Mouse Jiggler OFF")
  else
    startMouseJiggler()
    showAlert("Mouse Jiggler ON")
  end
end)

-- Mic: F5

hs.hotkey.bind({}, "F5", function()
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
end)

-- Lock EOD: F10

hs.hotkey.bind({"fn"}, "F10", function()
  stopMouseJiggler()
  showAlert("Mouse Jiggler OFF")

  hs.timer.doAfter(2, function()
    hs.eventtap.keyStroke({"ctrl", "cmd"}, "q")
  end)
end)

-- Lock: F6

hs.hotkey.bind({"fn"}, "F6", function()
  hs.eventtap.keyStroke({"ctrl", "cmd"}, "q")
end)

-- Screenshot: F1

hs.hotkey.bind({"fn"}, "F1", function()
  hs.eventtap.keyStroke({"ctrl", "cmd"}, "9")
end)