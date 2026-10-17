-- Bjorn ELRS finder for a 128x64 EdgeTX radio.
-- TRSS is downlink RSSI measured at the radio. 1RSS is an uplink fallback.
-- Both are real dBm readings; SNR and link quality are not dBm substitutes.
-- Install as bjfind.lua in SCRIPTS/TOOLS or SCRIPTS/TELEMETRY.

local DBM_MIN, DBM_MAX = -110, -40
local avg, peak, source, lastBeep, diagnostics
-- 24x21 Briard face: floppy ears, long fringe over the eyes, muzzle and beard.
-- The whole sprite stays in its own right-hand column on a 128x64 screen.
local DOG = {
  "###       ####       ###",
  "####     ######     ####",
  "#####   ########   #####",
  "########################",
  "########################",
  "###### ########## ######",
  " ##### ########## ##### ",
  " #####  ########  ##### ",
  "  ##### ######## #####  ",
  "  #####  ######  #####  ",
  "   #####  ####  #####   ",
  "   ######      ######   ",
  "    #### #    # ####    ",
  "    ####        ####    ",
  "     ####  ##  ####     ",
  "      ######## ####     ",
  "       ##########       ",
  "        ########        ",
  "         ######         ",
  "          ####          ",
  "           ##           ",
}

local function clamp(x, low, high)
  return math.max(low, math.min(high, x))
end

local function strengthFor(value, kind)
  if kind == "TRSS" or kind == "1RSS" then
    return clamp((value - DBM_MIN) * 100 / (DBM_MAX - DBM_MIN), 0, 100)
  elseif kind == "TSNR" or kind == "RSNR" then
    return clamp((value + 20) * 2.5, 0, 100)
  end
  return clamp(value, 0, 100)
end

local function signalText(value, kind)
  if kind == "TRSS" or kind == "1RSS" then
    return string.format("%d dBm", math.floor(value))
  elseif kind == "TSNR" or kind == "RSNR" then
    return string.format("%d dB", math.floor(value))
  end
  return string.format("%d%%", math.floor(value))
end

local function drawDog()
  for row, pixels in ipairs(DOG) do
    local pos = 1
    while true do
      local first, last = string.find(pixels, "#+", pos)
      if not first then break end
      lcd.drawFilledRectangle(104 + first - 1, row, last - first + 1, 1)
      pos = last + 1
    end
  end
end

local function readSignal()
  -- EdgeTX returns zero for a missing or stopped telemetry stream.
  -- A separate quality sensor can read zero while RSSI is still available.
  local downlink = getValue("TRSS")
  local uplink = getValue("1RSS")
  if type(downlink) == "number" and downlink < 0 and downlink >= -128 then
    return downlink, "TRSS", downlink, uplink
  end
  if type(uplink) == "number" and uplink < 0 and uplink >= -128 then
    return uplink, "1RSS", downlink, uplink
  end
  local tsnr = getValue("TSNR")
  if type(tsnr) == "number" and tsnr ~= 0 then
    return tsnr, "TSNR", downlink, uplink
  end
  local rsnr = getValue("RSNR")
  if type(rsnr) == "number" and rsnr ~= 0 then
    return rsnr, "RSNR", downlink, uplink
  end
  local tqly = getValue("TQly")
  if type(tqly) == "number" and tqly > 0 then
    return tqly, "TQly", downlink, uplink
  end
  local rqly = getValue("RQly")
  if type(rqly) == "number" and rqly > 0 then
    return rqly, "RQly", downlink, uplink
  end
  local legacy = getValue("RSSI")
  if type(legacy) == "number" and legacy > 0 then
    return legacy, "RSSI", downlink, uplink
  end
  return nil, nil, downlink, uplink
end

local function init()
  avg, peak, source, lastBeep, diagnostics = nil, nil, nil, nil, false
end

local function sensorText(name)
  if not getFieldInfo(name) then return "--" end
  local value = getValue(name)
  if type(value) ~= "number" then return "--" end
  return string.format("%d", math.floor(value))
end

local function drawDiagnostics()
  lcd.drawText(2, 1, "SENSORS", SMLSIZE)
  lcd.drawText(2, 14, "TR:" .. sensorText("TRSS"), SMLSIZE)
  lcd.drawText(52, 14, "1R:" .. sensorText("1RSS"), SMLSIZE)
  lcd.drawText(2, 24, "TS:" .. sensorText("TSNR"), SMLSIZE)
  lcd.drawText(52, 24, "RS:" .. sensorText("RSNR"), SMLSIZE)
  lcd.drawText(2, 34, "TQ:" .. sensorText("TQly"), SMLSIZE)
  lcd.drawText(52, 34, "RQ:" .. sensorText("RQly"), SMLSIZE)
  lcd.drawText(2, 44, "RI:" .. sensorText("RSSI"), SMLSIZE)
  lcd.drawText(2, 55, "ENT: back", SMLSIZE)
end

local function run(event)
  if event and EVT_VIRTUAL_EXIT and event == EVT_VIRTUAL_EXIT then return 1 end
  if event and EVT_VIRTUAL_ENTER and event == EVT_VIRTUAL_ENTER then
    diagnostics = not diagnostics
  end
  lcd.clear()
  local raw, currentSource, trss, rss1 = readSignal()
  drawDog()
  if diagnostics then
    drawDiagnostics()
    return 0
  end
  lcd.drawText(2, 1, "BJORN FINDER", SMLSIZE)
  lcd.drawRectangle(2, 44, 98, 10)
  if not raw then
    if source then lastBeep = nil end
    avg, peak, source = nil, nil, nil
    local now = getTime()
    if not lastBeep or now - lastBeep >= 150 then
      playTone(300, 45, 0, 0) -- distinct low heartbeat, not a proximity reading
      lastBeep = now
    end
    lcd.drawText(2, 14, "NO SIGNAL", MIDSIZE + BLINK)
    local down = type(trss) == "number" and trss or 0
    local up = type(rss1) == "number" and rss1 or 0
    lcd.drawText(2, 29, "Src:NA  Str:--", SMLSIZE)
    lcd.drawText(2, 36, string.format("TR:%d 1R:%d", down, up), SMLSIZE)
    lcd.drawText(2, 55, "ENT: sensors", SMLSIZE)
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
  local strength = strengthFor(avg, source)
  local beepStrength = strength
  if source ~= "TRSS" and source ~= "1RSS" then
    beepStrength = math.min(beepStrength, 60) -- link health is a coarse fallback
  end
  local period = 120 - beepStrength * 1.08 -- 1.2s far, 0.12s close for RSSI
  if not lastBeep or now - lastBeep >= period then
    playTone(math.floor(400 + beepStrength * 10), 35, 0, 0)
    lastBeep = now
  end

  lcd.drawText(2, 12, signalText(avg, source), DBLSIZE)
  lcd.drawText(2, 29, "Src:" .. source, SMLSIZE)
  lcd.drawText(2, 36, string.format("Str:%d%%", math.floor(strength + 0.5)), SMLSIZE)
  lcd.drawText(58, 36, string.format("Pk:%d", math.floor(peak)), SMLSIZE)
  local width = math.floor(96 * strength / 100)
  if width > 0 then lcd.drawFilledRectangle(3, 45, width, 8) end
  local peakPct = strengthFor(peak, source)
  local peakX = 3 + math.floor(95 * peakPct / 100)
  lcd.drawLine(peakX, 43, peakX, 54, SOLID, 0)
  local tip = "Sweep ENT:sensors"
  if source == "TSNR" or source == "RSNR" then tip = "SNR coarse ENT:diag" end
  if source == "TQly" or source == "RQly" or source == "RSSI" then
    tip = "LQ coarse ENT:diag"
  end
  lcd.drawText(2, 55, tip, SMLSIZE)
  return 0
end

return { init = init, run = run }
