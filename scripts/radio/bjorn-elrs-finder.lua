-- Bjorn ELRS finder for a 128x64 EdgeTX radio.
-- TRSS is downlink RSSI measured at the radio. 1RSS is an uplink fallback.
-- Both are real dBm readings; SNR and link quality are not dBm substitutes.
-- Install as bjfind.lua in SCRIPTS/TOOLS or SCRIPTS/TELEMETRY.

local DBM_MIN, DBM_MAX = -110, -40
local avg, peak, source, lastBeep

local function clamp(x, low, high)
  return math.max(low, math.min(high, x))
end

local function sensorExists(name)
  return getFieldInfo and getFieldInfo(name) ~= nil
end

local function readSignal()
  -- A discovered link-quality sensor at zero means packets have stopped.
  -- EdgeTX returns zero for telemetry values when its stream is absent.
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
  avg, peak, source, lastBeep = nil, nil, nil, nil
end

local function run(event)
  if event and EVT_VIRTUAL_EXIT and event == EVT_VIRTUAL_EXIT then return 1 end
  lcd.clear()
  local raw, currentSource = readSignal()
  if not raw then
    avg, peak, source, lastBeep = nil, nil, nil, nil
    lcd.drawText(2, 2, "BJORN FINDER", SMLSIZE)
    lcd.drawText(2, 16, "NO TELEMETRY", MIDSIZE + BLINK)
    lcd.drawText(2, 36, "Power model / check link", SMLSIZE)
    lcd.drawText(2, 47, "Discover TRSS or 1RSS", SMLSIZE)
    return 0
  end

  local now = getTime()
  if currentSource ~= source or not avg then
    avg, peak, source = raw, raw, currentSource
    lastBeep = nil
  else
    avg = avg * 0.8 + raw * 0.2
    peak = math.max(peak, avg)
  end
  if event and EVT_VIRTUAL_ENTER and event == EVT_VIRTUAL_ENTER then peak = avg end

  local strength = clamp((avg - DBM_MIN) * 100 / (DBM_MAX - DBM_MIN), 0, 100)
  local period = 120 - strength * 1.08 -- 1.2s far, 0.12s close
  if not lastBeep or now - lastBeep >= period then
    playTone(math.floor(400 + strength * 10), 35, 0, 0)
    lastBeep = now
  end

  lcd.drawText(2, 2, "BJORN FINDER", SMLSIZE)
  lcd.drawText(126, 2, source, SMLSIZE + RIGHT)
  lcd.drawText(2, 14, string.format("%d dBm", math.floor(avg)), DBLSIZE)
  lcd.drawText(79, 21, string.format("pk %d", math.floor(peak)), SMLSIZE)
  lcd.drawRectangle(2, 36, 124, 10)
  local width = math.floor(122 * strength / 100)
  if width > 0 then lcd.drawFilledRectangle(3, 37, width, 8) end
  local peakPct = clamp((peak - DBM_MIN) * 100 / (DBM_MAX - DBM_MIN), 0, 100)
  local peakX = 3 + math.floor(121 * peakPct / 100)
  lcd.drawLine(peakX, 35, peakX, 47, SOLID, 0)
  lcd.drawText(2, 53, source == "TRSS" and "Downlink  ENT:reset peak" or "Uplink fallback  ENT:reset", SMLSIZE)
  return 0
end

return { init = init, run = run }
