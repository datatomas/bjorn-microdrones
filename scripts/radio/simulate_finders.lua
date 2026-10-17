-- Desktop-only EdgeTX API simulation. No radio, serial, or network access.
local files = {
  "scripts/radio/bjorn-elrs-finder.lua",
  "scripts/radio/bjorn-elrs-finder-simple.lua",
}

for _, file in ipairs(files) do
  local clock, values, visible, tones, labels = 0, {}, {}, {}, {}
  local outlines, fills = 0, 0
  local full = string.find(file, "simple", 1, true) == nil
  SMLSIZE, MIDSIZE, DBLSIZE, BLINK, RIGHT, SOLID = 1, 2, 4, 8, 16, 0
  EVT_VIRTUAL_ENTER, EVT_VIRTUAL_EXIT = 101, 102
  getTime = function() return clock end
  getValue = function(name) return values[name] or 0 end
  getFieldInfo = function(name) return visible[name] and { id = 1 } or nil end
  playTone = function(freq, duration)
    tones[#tones + 1] = { freq = freq, duration = duration, at = clock }
  end
  lcd = {
    clear = function() labels, outlines, fills = {}, 0, 0 end,
    drawText = function(_, _, label) labels[#labels + 1] = label end,
    drawRectangle = function() outlines = outlines + 1 end,
    drawFilledRectangle = function() fills = fills + 1 end,
    drawLine = function() end,
  }

  local finder = assert(loadfile(file))()
  finder.init()
  local function step(t, readings, sensors, event)
    clock, values, visible = t, readings, sensors
    return finder.run(event or 0)
  end
  local function has(label)
    for _, text in ipairs(labels) do
      if text == label then return true end
    end
    return false
  end

  step(0, { TRSS = -90, ["1RSS"] = -55, TQly = 100, RQly = 100 },
       { TRSS = true, ["1RSS"] = true, TQly = true, RQly = true })
  assert((full and has("Src:TRSS") or not full and has("TRSS")) and #tones == 1,
         file .. ": downlink preference")
  if full then assert(has("Str:29%"), file .. ": numeric strength") end
  step(1, { TRSS = -90, ["1RSS"] = -55, TQly = 0, RQly = 100 },
       { TRSS = true, ["1RSS"] = true, TQly = true, RQly = true })
  if full then
    assert(has("Src:TRSS") and #tones == 1, file .. ": RSSI survives zero quality")
  end
  step(2, { TRSS = 0, ["1RSS"] = -55, TQly = 0, RQly = 100 },
       { TRSS = true, ["1RSS"] = true, TQly = true, RQly = true })
  assert((full and has("Src:1RSS") or not full and has("1RSS")) and #tones == 2,
         file .. ": uplink fallback")
  step(200, { TRSS = 0, ["1RSS"] = 0, TQly = 0, RQly = 0 },
       { TRSS = true, ["1RSS"] = true, TQly = true, RQly = true })
  if full then
    assert(has("NO SIGNAL") and has("Src:NA") and has("Tip: power RX / scan"),
           file .. ": no-signal labels")
    assert(#tones == 3 and tones[3].freq == 300,
           file .. ": distinct no-signal chirp")
    assert(outlines == 1 and fills > 0, file .. ": empty bar and dog visible")
    assert(has("Str:--") and has("TR:0 1R:0"), file .. ": raw RSSI shown")
  else
    assert(has("NO TELEMETRY") and #tones == 2, file .. ": loss silences tone")
  end
  step(201, { TRSS = -65, TQly = 100 }, { TRSS = true, TQly = true })
  assert((full and has("Src:TRSS") or not full and has("TRSS"))
         and #tones == (full and 4 or 3), file .. ": recovery")
  step(202, { TRSS = -40, TQly = 100 }, { TRSS = true, TQly = true })
  step(203, { TRSS = -100, TQly = 100 }, { TRSS = true, TQly = true }, EVT_VIRTUAL_ENTER)
  if full then
    assert(has("pk -68"), file .. ": peak reset")
    local count = #tones
    finder.init()
    step(300, { RSNR = 5 }, { RSNR = true })
    assert(has("Src:RSNR") and has("5 dB") and #tones == count + 1,
           file .. ": SNR fallback keeps dB units")
    step(301, { RQly = 70 }, { RQly = true })
    assert(has("Src:RQly") and has("70%") and #tones == count + 2,
           file .. ": link-quality fallback keeps percent units")
  end
  assert(step(400, {}, {}, EVT_VIRTUAL_EXIT) == 1, file .. ": tool exit")
  print(file .. ": source fallback, UI, tones, recovery, peak/exit OK")
end
