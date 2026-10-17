-- Desktop-only EdgeTX API simulation. No radio, serial, or network access.
local files = {
  "scripts/radio/bjorn-elrs-finder.lua",
  "scripts/radio/bjorn-elrs-finder-simple.lua",
}

for _, file in ipairs(files) do
  local clock, values, visible, tones, labels = 0, {}, {}, {}, {}
  SMLSIZE, MIDSIZE, DBLSIZE, BLINK, RIGHT, SOLID = 1, 2, 4, 8, 16, 0
  EVT_VIRTUAL_ENTER, EVT_VIRTUAL_EXIT = 101, 102
  getTime = function() return clock end
  getValue = function(name) return values[name] or 0 end
  getFieldInfo = function(name) return visible[name] and { id = 1 } or nil end
  playTone = function(freq, duration)
    tones[#tones + 1] = { freq = freq, duration = duration, at = clock }
  end
  lcd = {
    clear = function() labels = {} end,
    drawText = function(_, _, label) labels[#labels + 1] = label end,
    drawRectangle = function() end,
    drawFilledRectangle = function() end,
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
  assert(has("TRSS") and #tones == 1, file .. ": downlink preference")
  step(1, { TRSS = -90, ["1RSS"] = -55, TQly = 0, RQly = 100 },
       { TRSS = true, ["1RSS"] = true, TQly = true, RQly = true })
  assert(has("1RSS") and #tones == 2, file .. ": uplink fallback")
  step(200, { TRSS = -90, ["1RSS"] = -55, TQly = 0, RQly = 0 },
       { TRSS = true, ["1RSS"] = true, TQly = true, RQly = true })
  assert(has("NO TELEMETRY") and #tones == 2, file .. ": loss silences tone")
  step(201, { TRSS = -65, TQly = 100 }, { TRSS = true, TQly = true })
  assert(has("TRSS") and #tones == 3, file .. ": recovery")
  step(202, { TRSS = -40, TQly = 100 }, { TRSS = true, TQly = true })
  step(203, { TRSS = -100, TQly = 100 }, { TRSS = true, TQly = true }, EVT_VIRTUAL_ENTER)
  if string.find(file, "simple", 1, true) == nil then
    assert(has("pk -68"), file .. ": peak reset")
  end
  assert(step(204, {}, {}, EVT_VIRTUAL_EXIT) == 1, file .. ": tool exit")
  print(file .. ": downlink, fallback, loss, recovery, peak/exit OK")
end
