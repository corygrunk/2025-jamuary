-- Jamuary 2025 - 05
--- explore lfo viz


TAB = require('tabutil')
MusicUtil = require('musicutil')

pattern_time = require 'pattern_time'
_lfos = require 'lfo'

scope = {1}
scope_vals = {}
lfo_period = 1
lfo_depth = 1

alt_mode = false

function init()

  for i = 1, 127 do
    scope_vals[i] = 0
  end

  lfo_1 = _lfos:add{ -- establish an LFO variable for a specific purpose:
    shape = 'sine', -- shape
    min = 0, -- min
    max = 10, -- max
    depth = lfo_depth, -- depth (0 to 1)
    mode = 'clocked', -- mode
    period = lfo_period, -- period (in 'clocked' mode, represents beats)
    -- pass our 'scaled' value (bounded by min/max and depth) to the engine:
    action = function(scaled, raw) update_scope_vals(scaled) end -- action, always passes scaled and raw values
    }

  lfo_1:start() -- start our LFO, complements ':stop()'

  clock.run(redraw_clock)
  screen_dirty = true
end


function update_scope_vals(val)
  table.remove(scope_vals, 1)
  scope_vals[127] = val

  crow.output[3].volts = val
  screen_dirty = true
end


function key(n,z)
  if n == 1 and z == 1 then
    alt_mode = true
    print('ALT MODE')
  elseif n == 1 and z == 0 then
    alt_mode = false
  elseif n == 2 and z == 1 then
    print('K2')
  elseif n == 3 and z == 1 then
    print('K3')
  end
  screen_dirty = true
end


function enc(n,d)
  if n == 1 then
    print('enc 1')
  end
  if n == 2 then
    lfo_period = util.clamp(lfo_period + d/10, 0.5, 20)
    lfo_1:set('period', lfo_period)
  end
  if n == 3 then
    lfo_depth = util.clamp(lfo_depth + d/100, 0, 1)
    lfo_1:set('depth', lfo_depth)
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

  for i = 1, 127 do
    screen.level(15)
    screen.pixel(i+1, scope_vals[i]*-2.8+31)
    screen.fill()
  end

  screen.level(3)
  screen.move(10, 45)
  screen.text(string.format('%.2f',lfo_period))
  screen.move(10, 55)
  screen.text(string.format('%.2f',lfo_depth)) 

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
