-- Bjorn ELRS finder for a 128x64 EdgeTX radio.
-- TRSS is downlink RSSI measured at the radio. 1RSS is an uplink fallback.
-- Both are real dBm readings; SNR and link quality are not dBm substitutes.
-- Install as bjfind.lua in SCRIPTS/TOOLS or SCRIPTS/TELEMETRY.

local DBM_MIN, DBM_MAX = -110, -40
local avg, peak, source, lastBeep
local DOG = {
  "  ###      ###  ",
  " #####    ##### ",
  "######    ######",
  "################",
  "###### ## ######",
  "#####      #####",
  "######    ######",
  "################",
  " ######  ###### ",
  "  #####  #####  ",
  "   ##########   ",
  "    ###  ###    ",
  "     ######     ",
  "      ####      ",
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
      lcd.drawFilledRectangle(110 + first - 1, row - 1, last - first + 1, 1)
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
  avg, peak, source, lastBeep = nil, nil, nil, nil
end

local function run(event)
  if event and EVT_VIRTUAL_EXIT and event == EVT_VIRTUAL_EXIT then return 1 end
  lcd.clear()
  local raw, currentSource, trss, rss1 = readSignal()
  lcd.drawText(2, 2, "BJORN FINDER", SMLSIZE)
  drawDog()
  lcd.drawRectangle(2, 36, 124, 10)
  if not raw then
    if source then lastBeep = nil end
    avg, peak, source = nil, nil, nil
    local now = getTime()
    if not lastBeep or now - lastBeep >= 150 then
      playTone(300, 45, 0, 0) -- distinct low heartbeat, not a proximity reading
      lastBeep = now
    end
    lcd.drawText(2, 16, "NO SIGNAL", MIDSIZE + BLINK)
    lcd.drawText(74, 18, "Src:NA", SMLSIZE)
    local down = type(trss) == "number" and trss or 0
    local up = type(rss1) == "number" and rss1 or 0
    lcd.drawText(2, 27, "Str:--", SMLSIZE)
    lcd.drawText(67, 27, string.format("TR:%d 1R:%d", down, up), SMLSIZE)
    lcd.drawText(2, 53, "Tip: power RX / scan", SMLSIZE)
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

  lcd.drawText(2, 16, signalText(avg, source), DBLSIZE)
  lcd.drawText(74, 17, "Src:" .. source, SMLSIZE)
  lcd.drawText(2, 27, string.format("Str:%d%%", math.floor(strength + 0.5)), SMLSIZE)
  lcd.drawText(74, 27, string.format("pk %d", math.floor(peak)), SMLSIZE)
  local width = math.floor(122 * strength / 100)
  if width > 0 then lcd.drawFilledRectangle(3, 37, width, 8) end
  local peakPct = strengthFor(peak, source)
  local peakX = 3 + math.floor(121 * peakPct / 100)
  lcd.drawLine(peakX, 35, peakX, 47, SOLID, 0)
  local tip = "Tip: sweep ENT=reset"
  if source == "TSNR" or source == "RSNR" then tip = "Tip: SNR is coarse" end
  if source == "TQly" or source == "RQly" or source == "RSSI" then
    tip = "Tip: LQ is coarse"
  end
  lcd.drawText(2, 53, tip, SMLSIZE)
  return 0
end

return { init = init, run = run }
