-- Jamuary 2025 - 11
-- It's pattern time!

Tab = require('tabutil')
MusicUtil = require 'musicutil'
pattern_time = require 'pattern_time'

engine.name = 'PolySub'

hs = include('lib/halfsecond')

scale = {}
scale_names = {}

timbre = 0.1
attack = 0.01
release = 0.2

armed = 0
note_name = ''

function init()

  hs.init()

  pat = pattern_time.new() -- establish a pattern recorder
  pat.process = play_pattern -- assign the function to be executed when the pattern plays back

  engine.detune(1)
  engine.timbre(timbre)
  engine.ampRel(release)
  engine.ampAtk(attack)

  params:add{type = "option", id = "scale_mode", name = "scale mode",
  options = scale_names, default = 5,
  action = function() build_scale() end}

  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 60, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function() build_scale() end}

  build_scale() -- builds initial scale

  clock.run(redraw_clock)
  screen_dirty = true
end

function build_scale()
  scale = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 16)
  local num_to_add = 16 - #scale
  for i = 1, num_to_add do
    table.insert(scale, scale[16 - num_to_add])
  end
end

function record_pat_value() -- storing values to recall in the pattern
  pat:watch(
    {
      ["value"] = key_value,
      ["voice"] = key_voice,
      ["state"] = key_state,
    }
  )
end

function play_pattern(data) -- what to do with those values when the pattern runs
  if data.state == 1 then
    note_on(data.value,data.voice)
  elseif data.state == 0 then
    note_off(data.voice)
  end
  screen_dirty = true
end

function note_on(note,voice)
  note_name = MusicUtil.note_num_to_name(note,true)
  engine.start(voice,MusicUtil.note_num_to_freq(note))
end

function note_off(voice)
  note_name = ''
  engine.stop(voice)
end

function key(n,z)
  if n == 1 and z == 1 then
    pat:set_overdub(1)
  elseif n == 1 and z == 0 then
    pat:set_overdub(0)
  elseif n == 2 and z == 1 then
    local n = scale[math.random(1,16)]
    key_value = n
    key_voice = 1
    key_state = 1
    record_pat_value()
    note_on(n,1)
  elseif n == 2 and z == 0 then
    key_value = n
    key_voice = 1
    key_state = 0
    record_pat_value()
    note_off(1)
  elseif n == 3 and z == 1 then
    note_off(1)
    pat:clear()
    pat:stop()
    pat:rec_start()
  elseif n == 3 and z == 0 then
    pat:rec_stop()
    if pat.count > 0 then
      pat:start()
    end
  end
  screen_dirty = true
end


function enc(n,d)
  if n == 1 then
    timbre = util.clamp(timbre + d/100,0,2)
    engine.timbre(timbre)
  elseif n == 2 then
    attack = util.clamp(attack + d/100,0,2)
    engine.ampAtk(attack)
  elseif n == 3 then
    release = util.clamp(release + d/100,0,2)
    engine.ampRel(release)
  end
  screen_dirty = true
end


function redraw()
  screen.clear()
  screen.aa(1)
  screen.font_face(1)
  screen.font_size(8)
  screen.level(15)
  -- screen.pixel(0, 0) ----------- make a pixel at the north-western most terminus
  -- screen.pixel(127, 0) --------- and at the north-eastern
  -- screen.pixel(127, 63) -------- and at the south-eastern
  -- screen.pixel(0, 63) ---------- and at the south-western

  screen.level(6)
  screen.move(10, 45)
  screen.text('timbre')
  screen.level(15)
  screen.move(10, 55)
  screen.text(string.format('%.2f',timbre))

  screen.level(6)
  screen.move(50, 45)
  screen.text('atk')
  screen.level(15)
  screen.move(50, 55)
  screen.text(string.format('%.2f',attack))

  screen.level(6)
  screen.move(80, 45)
  screen.text('rel')
  screen.level(15)
  screen.move(80, 55)
  screen.text(string.format('%.2f',release))

  screen.move(110,55)
  if pat.rec == 1 then
    screen.text('rec')
  elseif pat.play == 1 and pat.overdub == 1 then
    screen.text('ovr')
  end

  screen.level(6)
  screen.font_face(10)
  screen.font_size(24)
  screen.move (110, 30)
  screen.text_right(note_name)

  screen.fill() ---------------- fill the termini and message at once
  screen.update() -------------- update space

  screen_dirty = false
end


function redraw_clock()
  while true do
    clock.sleep(1/15)
    if screen_dirty then
      redraw()
      screen_dirty = false
    end
  end
end



-- UTILITY TO RESTART SCRIPT FROM MAIDEN
function r()
  norns.script.load(norns.state.script)
end
