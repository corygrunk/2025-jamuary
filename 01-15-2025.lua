-- Jamuary 2025 - 15
-- It's pattern time!

g = grid.connect() -- if no argument is provided, defaults to port 1

Tab = require('tabutil')
MusicUtil = require 'musicutil'
pattern_time = require 'pattern_time'
_lfos = require 'lfo'

engine.name = 'PolySub'
MAXNUMVOICES = 16
nvoices = 0

scale = {}
scale_names = {}

lfo_period = 1
attack = 0.01
release = 0.2

armed = 0
note_name = ''

function init()

  pat = pattern_time.new() -- establish a pattern recorder
  pat.process = play_pattern -- assign the function to be executed when the pattern plays back

  engine.detune(1)
  engine.timbre(1)
  engine.ampRel(release)
  engine.ampAtk(attack)

  -- REFERENCE - LFO.new(shape, min, max, depth, mode, period, action)
  simple_lfo = _lfos.new('sine', 0, 1, 1, 'free', lfo_period, function(scaled, raw) engine.timbre(scaled)  end)
  simple_lfo:start()

  for i = 1, #MusicUtil.SCALES do
    table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
  end

  params:add{type = "option", id = "scale_mode", name = "scale mode",
  options = scale_names, default = 5,
  action = function() build_scale() end}

  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 60, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function() build_scale() end}

  build_scale() -- builds initial scale

  clock.run(redraw_clock)
  grid_redraw()
  screen_dirty = true
end

function build_scale()
  scale = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 16)
  local num_to_add = 16 - #scale
  for i = 1, num_to_add do
    table.insert(scale, scale[#scale]) -- Repeat the last note if needed
  end
end

function record_pat_value() -- storing values to recall in the pattern
  pat:watch(
    {
      ["value"] = key_value,
      ["state"] = key_state
    }
  )
end

function play_pattern(data) -- what to do with those values when the pattern runs
  if data.state == 1 then
    note_on(data.value,nvoices)
  elseif data.state == 0 then
    note_off(nvoices)
  end
  screen_dirty = true
end

function note_on(note)
  if nvoices < MAXNUMVOICES then
    nvoices = nvoices + 1
    note_name = MusicUtil.note_num_to_name(note,true)
    engine.start(nvoices,MusicUtil.note_num_to_freq(note))
  end
  print(nvoices)
end

function note_off()
  note_name = ''
  engine.stop(nvoices)
  nvoices = nvoices - 1
  print(nvoices)
end

function g.key(x,y,z)
  print(x .. ',' .. y .. ',' .. z)
  if x > 12 and y > 4 then
    local note_num = 0
    if x == 13 and y == 8 then note_num = scale[1]
    elseif x == 14 and y == 8 and z == 1 then note_num = scale[2]
    elseif x == 15 and y == 8 and z == 1 then note_num = scale[3]
    elseif x == 16 and y == 8 and z == 1 then note_num = scale[4]
    elseif x == 13 and y == 7 and z == 1 then note_num = scale[5]
    elseif x == 14 and y == 7 and z == 1 then note_num = scale[6]
    elseif x == 15 and y == 7 and z == 1 then note_num = scale[7]
    elseif x == 16 and y == 7 and z == 1 then note_num = scale[8]
    elseif x == 13 and y == 6 and z == 1 then note_num = scale[9]
    elseif x == 14 and y == 6 and z == 1 then note_num = scale[10]
    elseif x == 15 and y == 6 and z == 1 then note_num = scale[11]
    elseif x == 16 and y == 6 and z == 1 then note_num = scale[12]
    elseif x == 13 and y == 5 and z == 1 then note_num = scale[13]
    elseif x == 14 and y == 5 and z == 1 then note_num = scale[14]
    elseif x == 15 and y == 5 and z == 1 then note_num = scale[15]
    elseif x == 16 and y == 5 and z == 1 then note_num = scale[16]
    end
    if z == 1 then
      key_value = note_num
      key_state = 1
      record_pat_value()
      note_on(note_num)
    else
      key_value = scale[y]
      key_state = 0
      record_pat_value()
      note_off()
    end
  end
  grid_redraw()
  screen_dirty = true
end

function grid_redraw()
  g:all(0) -- turn all the LEDs off...

  for i = 13, 16 do
    for n = 5, 8 do
      g:led(i,n,1)
    end
  end

  g:led(13,8,3)
  g:led(15,5,3)
  g:led(16,7,3)

  g:refresh() -- refresh the grid
end

function key(n,z)
  if n == 1 and z == 1 then
    pat:set_overdub(1)
  elseif n == 1 and z == 0 then
    pat:set_overdub(0)
  elseif n == 2 and z == 1 then
    local n = scale[math.random(1,16)]
    key_value = n
    key_state = 1
    record_pat_value()
    note_on(n)
  elseif n == 2 and z == 0 then
    key_value = n
    key_state = 0
    record_pat_value()
    note_off()
  elseif n == 3 and z == 1 then
    engine.stopAll()
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
    lfo_period = util.clamp(lfo_period + d/10,0.1,20)
    simple_lfo:set('period',lfo_period)
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
  screen.text('lfo')
  screen.level(15)
  screen.move(10, 55)
  screen.text(string.format('%.2f',lfo_period))

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
