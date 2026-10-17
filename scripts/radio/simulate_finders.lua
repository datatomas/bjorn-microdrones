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
  playFile = function(path)
    tones[#tones + 1] = { path = path, at = clock }
  end
  lcd = {
    clear = function() labels, outlines, fills = {}, 0, 0 end,
    drawText = function(x, y, label, flags)
      labels[#labels + 1] = label
      if full then
        local width = flags == DBLSIZE and 12 or flags == MIDSIZE + BLINK and 8 or 5
        local height = flags == DBLSIZE and 16 or flags == MIDSIZE + BLINK and 12 or 7
        assert(x + #label * width <= 128 and y + height <= 64, "text outside screen: " .. label)
        assert(y >= 22 or x + #label * width <= 104, "text overlaps Briard: " .. label)
      end
    end,
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
    assert(has("NO SIGNAL") and has("Src:NA  Str:--") and has("ENT: sensors"),
           file .. ": no-signal labels")
    assert(#tones == 3 and tones[3].path == "/SOUNDS/bjorn/bjwait.wav",
           file .. ": distinct no-signal double bark")
    assert(outlines == 1 and fills > 0, file .. ": empty bar and dog visible")
    assert(has("Src:NA  Str:--") and has("TR:0 1R:0"), file .. ": raw RSSI shown")
  else
    assert(has("NO TELEMETRY") and #tones == 2, file .. ": loss silences tone")
  end
  step(201, { TRSS = -65, TQly = 100 }, { TRSS = true, TQly = true })
  assert((full and has("Src:TRSS") or not full and has("TRSS"))
         and #tones == (full and 4 or 3), file .. ": recovery")
  step(202, { TRSS = -40, TQly = 100 }, { TRSS = true, TQly = true })
  step(203, { TRSS = -100, TQly = 100 }, { TRSS = true, TQly = true }, EVT_VIRTUAL_ENTER)
  if full then
    assert(has("SENSORS") and has("TR:-100") and has("1R:--"),
           file .. ": diagnostics distinguish missing sensors")
    step(204, { TRSS = 0 }, { TRSS = true })
    assert(has("TR:0") and has("1R:--"), file .. ": zero versus missing")
    step(205, { TRSS = -65 }, { TRSS = true }, EVT_VIRTUAL_ENTER)
    assert(has("Src:TRSS"), file .. ": return from diagnostics")
    finder.init()
    step(1000, { TRSS = -40 }, { TRSS = true })
    local barkCount = #tones
    step(1039, { TRSS = -40 }, { TRSS = true })
    assert(#tones == barkCount, file .. ": no overlapping bark scheduling")
    step(1040, { TRSS = -40 }, { TRSS = true })
    assert(#tones == barkCount + 1 and tones[#tones].path == "/SOUNDS/bjorn/bjbark.wav",
           file .. ": strong signal bark interval")
    finder.init()
    step(2000, { TRSS = -110 }, { TRSS = true })
    barkCount = #tones
    step(2179, { TRSS = -110 }, { TRSS = true })
    assert(#tones == barkCount, file .. ": weak signal waits")
    step(2180, { TRSS = -110 }, { TRSS = true })
    assert(#tones == barkCount + 1, file .. ": weak signal bark interval")
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
  print(file .. ": source fallback, UI, tones, recovery, diagnostics/exit OK")
end
