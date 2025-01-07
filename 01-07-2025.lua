-- Jamuary 2025 - 07
--- PolySub w filter pinging

TAB = require('tabutil')
MusicUtil = require('musicutil')

s = require 'sequins'
engine.name = 'PolySub'
arp = s{60,64,67,71,72,71,67,64} -- STRANGER THINGS ARPEGGIO
syncs = s{1/4,1/4,1/4,1/4,1/2,1/2}
counter = 0

hs = include('lib/halfsecond')

playing = true


pattern_time = require 'pattern_time' -- not using yet
_lfos = require 'lfo'

scope = {1,1,1}
scope_vals = {{},{},{}}
lfo_shapes = {'sine', 'tri', 'up', 'down', 'random'}
lfo_shape_selected = {2,3,5}
lfo_min = {0,0,0.1}
lfo_max = {1,1,1}
lfo_period = {2,3,2}
lfo_depth = {1,1,0.5}
lfo_selected = 1

alt_mode = false

function init()
  
  hs.init()

  -- amplitude envelope params
  -- engine.ampAtk(0.05)
  -- engine.ampCurve(-1.0)
  -- engine.ampDec(0.1)
  -- engine.ampRel(1.0)
  -- engine.ampSus(1.0)
  engine.ampAtk(0.05)
  engine.ampCurve(-1.0)
  engine.ampDec(0.1)
  engine.ampSus(0.1)
  engine.ampRel(0.1)

  engine.cut(8.0) -- RLPF cutoff frequency as ratio of fundamental
  
  -- filter envelope params
  engine.cutAtk(0.0)
  engine.cutCurve(-1.0)
  engine.cutDec(0.0)
  engine.cutEnvAmt(0.0)
  engine.cutRel(1.0)
  engine.cutSus(1.0)

  engine.detune(0.2) -- linear frequency detuning between channels
  engine.fgain(0.0) -- filter gain (moogFF model)
  engine.hzLag(0.2)
  engine.level(0.2)
  engine.noise(0.0) -- pink noise level (before filter)
  engine.shape(0.0) -- base waveshape selection
  engine.sub(0.1) -- sub-octave sine level
  engine.timbre(0.5) -- modulation of waveshape
  engine.width(0.5) -- stereo width

  for i = 1, TAB.count(scope_vals) do
    for n = 1, 127 do
      scope_vals[i][n] = 0
    end
  end

  lfo_1 = _lfos:add{ -- establish an LFO variable for a specific purpose:
    shape = lfo_shapes[lfo_shape_selected[1]], -- shape
    min = lfo_min[1], -- min
    max = lfo_max[1], -- max
    depth = lfo_depth[1], -- depth (0 to 1)
    mode = 'clocked', -- mode
    period = lfo_period[1], -- period (in 'clocked' mode, represents beats)
    ppqn = 24,
    -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
    action = function(scaled, raw) update_scope_vals(1,raw); engine.timbre(scaled) end -- action, always passes scaled and raw values
    }
  lfo_1:start() -- start our LFO, complements ':stop()'

  lfo_2 = _lfos:add{ -- establish an LFO variable for a specific purpose:
    shape = lfo_shapes[lfo_shape_selected[2]], -- shape
    min = lfo_min[2], -- min
    max = lfo_max[2], -- max
    depth = lfo_depth[2], -- depth (0 to 1)
    mode = 'clocked', -- mode
    period = lfo_period[2], -- period (in 'clocked' mode, represents beats)
    ppqn = 24,
    -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
    action = function(scaled, raw) update_scope_vals(2,raw); engine.shape(scaled) end -- action, always passes scaled and raw values
  }
  lfo_2:start() -- start our LFO, complements ':stop()'

  lfo_3 = _lfos:add{ -- establish an LFO variable for a specific purpose:
    shape = lfo_shapes[lfo_shape_selected[3]], -- shape
    min = lfo_min[3], -- min
    max = lfo_max[3], -- max
    depth = lfo_depth[3], -- depth (0 to 1)
    mode = 'clocked', -- mode
    period = lfo_period[3], -- period (in 'clocked' mode, represents beats)
    ppqn = 24,
    -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
    action = function(scaled, raw) update_scope_vals(3,raw); engine.ampDec(scaled) end -- action, always passes scaled and raw values
  }
  lfo_3:start() -- start our LFO, complements ':stop()'


  -- NOT IN UI -- filter pinging
  filter_lfo = _lfos:add{ -- establish an LFO variable for a specific purpose:
    shape = 'up', -- shape
    min = 0, -- min
    max = 4, -- max
    depth = 1, -- depth (0 to 1)
    mode = 'clocked', -- mode
    period = 4, -- period (in 'clocked' mode, represents beats)
    ppqn = 24,
    -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
    action = function(scaled, raw) engine.fgain(scaled) end -- action, always passes scaled and raw values
  }
  filter_lfo:start() -- start our LFO, complements ':stop()'


  clock.run(seq_clock)
  clock.run(redraw_clock)
  screen_dirty = true
end


function update_scope_vals(instance,val)
  for i = 1, instance do
    table.remove(scope_vals[instance], 1)
    scope_vals[instance][127] = val*10
  end
  screen_dirty = true
end

function seq_clock()
  while true do
    -- clock.sleep(syncs[math.random(1,TAB.count(syncs))])
    clock.sleep(syncs())
    if playing then
      counter = counter + 1

      local incoming_note = arp()
      arp:step(math.random(1,4))
      note_off()
      note_on(incoming_note)

      if counter % 4 == 0 then

      end
    end
  end
end

function note_on(note)
  engine.start(1,MusicUtil.note_num_to_freq(note - 12))
end

function note_off()
  engine.stopAll()
end


function key(n,z)
  if n == 1 and z == 1 then
    alt_mode = true
    if playing then
      playing = false
    else
      note_off()
      playing = true
    end
    print('ALT MODE')
  elseif n == 1 and z == 0 then
    alt_mode = false
  elseif n == 2 and z == 1 and not alt_mode then
    lfo_selected = util.wrap(lfo_selected - 1, 1, 3)
  elseif n == 3 and z == 1 and not alt_mode then
    lfo_selected = util.wrap(lfo_selected + 1, 1, 3)
  end
  screen_dirty = true
end


function enc(n,d)
  if n == 1 then
    lfo_shape_selected[lfo_selected] = util.wrap(lfo_shape_selected[lfo_selected] + d, 1, TAB.count(lfo_shapes))
    -- incredibly hacky implementation
    if lfo_selected == 1 then lfo_1:set('shape', lfo_shapes[lfo_shape_selected[lfo_selected]]) end
    if lfo_selected == 2 then lfo_2:set('shape', lfo_shapes[lfo_shape_selected[lfo_selected]]) end
    if lfo_selected == 3 then lfo_3:set('shape', lfo_shapes[lfo_shape_selected[lfo_selected]]) end
    
  end
  if n == 2 then
    lfo_period[lfo_selected] = util.clamp(lfo_period[lfo_selected] + d/10, 0.25, 20)
    -- incredibly hacky implementation
    if lfo_selected == 1 then lfo_1:set('period', lfo_period[lfo_selected]) end
    if lfo_selected == 2 then lfo_2:set('period', lfo_period[lfo_selected]) end
    if lfo_selected == 3 then lfo_3:set('period', lfo_period[lfo_selected]) end
  end
  if n == 3 then
    lfo_depth[lfo_selected] = util.clamp(lfo_depth[lfo_selected] + d/100, 0, 1)
    -- incredibly hacky implementation
    if lfo_selected == 1 then lfo_1:set('depth', lfo_depth[lfo_selected]) end
    if lfo_selected == 2 then lfo_2:set('depth', lfo_depth[lfo_selected]) end
    if lfo_selected == 3 then lfo_3:set('depth', lfo_depth[lfo_selected]) end
  end
  screen_dirty = true
end


function redraw()
  screen.clear()
  screen.aa(1)
  screen.font_face(1)
  screen.font_size(8)
  screen.level(15)
  screen.line_width(1)

  if playing == false then
    screen.level(15)
    screen.move(63,31)
    screen.text_center('PAUSED')
  else
    for i = 1, TAB.count(scope_vals) do
      if lfo_selected == i then screen.level(15) else screen.level(2) end
      for n = 1, 127 do
        screen.pixel(n+1, scope_vals[i][n]*-2.8+31)
        screen.fill()
      end
    end
  
    for i = 1, TAB.count(scope_vals) do
      if lfo_selected == i then screen.level(15) else screen.level(3) end
      screen.move(10 + (i-1)*40, 40)
      screen.text(lfo_shapes[lfo_shape_selected[i]])
      screen.move(10 + (i-1)*40, 50)
      screen.text(string.format('%.2f',lfo_period[i]))
      screen.move(10 + (i-1)*40, 60)
      screen.text(string.format('%.2f',lfo_depth[i]))
    end
  end

  screen.fill()
  screen.update()

  screen_dirty = false
end


function redraw_clock()
  while true do
    clock.sleep(1/30)
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
