-- Simple Bjorn ELRS finder for a 128x64 EdgeTX radio.
-- TRSS is the radio-side downlink RSSI; 1RSS is an uplink fallback.
-- Install as bjsimp.lua in SCRIPTS/TOOLS or SCRIPTS/TELEMETRY.

local source, lastBeep

local function sensorExists(name)
  return getFieldInfo and getFieldInfo(name) ~= nil
end

local function readSignal()
  local value = getValue("TRSS")
  if type(value) == "number" and value < 0 and value >= -128
      and (not sensorExists("TQly") or getValue("TQly") > 0) then
    return value, "TRSS"
  end
  if sensorExists("RQly") and getValue("RQly") == 0 then return nil end
  value = getValue("1RSS")
  if type(value) == "number" and value < 0 and value >= -128 then
    return value, "1RSS"
  end
  return nil
end

local function init()
  source, lastBeep = nil, nil
end

local function run(event)
  if event and EVT_VIRTUAL_EXIT and event == EVT_VIRTUAL_EXIT then return 1 end
  lcd.clear()
  local dbm, currentSource = readSignal()
  if not dbm then
    source, lastBeep = nil, nil
    lcd.drawText(2, 2, "BJORN SIMPLE", SMLSIZE)
    lcd.drawText(2, 18, "NO TELEMETRY", MIDSIZE + BLINK)
    return 0
  end

  local strength = math.max(0, math.min(100, (dbm + 110) * 100 / 70))
  local now = getTime()
  if currentSource ~= source then
    source, lastBeep = currentSource, nil
  end
  if not lastBeep or now - lastBeep >= 120 - strength * 1.08 then
    playTone(math.floor(400 + strength * 10), 35, 0, 0)
    lastBeep = now
  end

  lcd.drawText(2, 2, "BJORN SIMPLE", SMLSIZE)
  lcd.drawText(126, 2, source, SMLSIZE + RIGHT)
  lcd.drawText(2, 16, string.format("%d dBm", math.floor(dbm)), DBLSIZE)
  lcd.drawRectangle(2, 38, 124, 10)
  local width = math.floor(122 * strength / 100)
  if width > 0 then lcd.drawFilledRectangle(3, 39, width, 8) end
  lcd.drawText(2, 53, source == "TRSS" and "Downlink" or "Uplink fallback", SMLSIZE)
  return 0
end

return { init = init, run = run }
