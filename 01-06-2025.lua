-- Jamuary 2025 - 06
--- three LFOS for crow


TAB = require('tabutil')
MusicUtil = require('musicutil')

_lfos = require 'lfo'

hs = include('lib/halfsecond')

scope = {1,1,1}
scope_vals = {{},{},{}}
lfo_shapes = {'sine', 'tri', 'up', 'down', 'random'}
lfo_shape_selected = {3,2,1}
lfo_period = {2,6,0.2}
lfo_depth = {0.5,0.5,0.25}
lfo_selected = 1

alt_mode = false

function init()

  hs.init()

  for i = 1, TAB.count(scope_vals) do
    for n = 1, 127 do
      scope_vals[i][n] = 0
    end
  end

  lfo_1 = _lfos:add{ -- establish an LFO variable for a specific purpose:
    shape = lfo_shapes[lfo_shape_selected[1]], -- shape
    min = 0, -- min
    max = 10, -- max
    depth = lfo_depth[1], -- depth (0 to 1)
    mode = 'clocked', -- mode
    period = lfo_period[1], -- period (in 'clocked' mode, represents beats)
    ppqn = 24,
    -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
    action = function(scaled, raw) update_scope_vals(1,scaled) end -- action, always passes scaled and raw values
    }
  lfo_1:start() -- start our LFO, complements ':stop()'

  lfo_2 = _lfos:add{ -- establish an LFO variable for a specific purpose:
    shape = lfo_shapes[lfo_shape_selected[2]], -- shape
    min = 0, -- min
    max = 10, -- max
    depth = lfo_depth[2], -- depth (0 to 1)
    mode = 'clocked', -- mode
    period = lfo_period[2], -- period (in 'clocked' mode, represents beats)
    ppqn = 24,
    -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
    action = function(scaled, raw) update_scope_vals(2,scaled) end -- action, always passes scaled and raw values
  }
  lfo_2:start() -- start our LFO, complements ':stop()'

  lfo_3 = _lfos:add{ -- establish an LFO variable for a specific purpose:
  shape = lfo_shapes[lfo_shape_selected[3]], -- shape
  min = 0, -- min
  max = 10, -- max
  depth = lfo_depth[3], -- depth (0 to 1)
  mode = 'clocked', -- mode
  period = lfo_period[3], -- period (in 'clocked' mode, represents beats)
  ppqn = 24,
  -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
  action = function(scaled, raw) update_scope_vals(3,scaled) end -- action, always passes scaled and raw values
}
lfo_3:start() -- start our LFO, complements ':stop()'

  clock.run(redraw_clock)
  screen_dirty = true
end


function update_scope_vals(instance,val)
  for i = 1, instance do
    table.remove(scope_vals[instance], 1)
    scope_vals[instance][127] = val
    crow.output[instance].volts = val
  end
  screen_dirty = true
end


function key(n,z)
  if n == 1 and z == 1 then
    alt_mode = true
    print('ALT MODE')
  elseif n == 1 and z == 0 then
    alt_mode = false
  elseif n == 2 and z == 1 then
    lfo_selected = util.wrap(lfo_selected - 1, 1, 3)
  elseif n == 3 and z == 1 then
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
    lfo_period[lfo_selected] = util.clamp(lfo_period[lfo_selected] + d/10, 0.5, 20)
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

  -- screen.level(6)
  -- screen.pixel(63, 31) -------- pixel in center of screen
  -- screen.fill()

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
